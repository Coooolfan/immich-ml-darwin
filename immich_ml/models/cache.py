import asyncio
from typing import Any

from aiocache.backends.memory import SimpleMemoryCache
from aiocache.lock import OptimisticLock
from aiocache.plugins import TimingPlugin

from immich_ml.config import log
from immich_ml.models import from_model_type
from immich_ml.models.base import InferenceModel

from ..schemas import ModelTask, ModelType, has_profiling


class UnloadingMemoryCache(SimpleMemoryCache):
    def __delete(self, key: str) -> int:
        self._unload_cached_model(key)
        if self._cache.pop(key, None) is not None:
            handle = self._handlers.pop(key, None)
            if handle:
                handle.cancel()
            return 1
        return 0

    def _unload_cached_model(self, key: str) -> None:
        model = self._cache.get(key)
        unload = getattr(model, "unload_when_idle", None)
        if callable(unload):
            unload()

    async def _set(
        self,
        key: str,
        value: Any,
        ttl: int | float | None = None,
        _cas_token: Any = None,
        _conn: Any = None,
    ) -> bool:
        if _cas_token is not None and _cas_token != self._cache.get(key):
            return False

        if key in self._handlers:
            self._handlers[key].cancel()

        self._cache[key] = value
        if ttl:
            loop = asyncio.get_running_loop()
            self._handlers[key] = loop.call_later(ttl, self.__delete, key)
        return True

    async def _expire(self, key: str, ttl: int, _conn: Any = None) -> bool:
        if key in self._cache:
            handle = self._handlers.pop(key, None)
            if handle:
                handle.cancel()
            if ttl:
                loop = asyncio.get_running_loop()
                self._handlers[key] = loop.call_later(ttl, self.__delete, key)
            return True

        return False

    async def _delete(self, key: str, _conn: Any = None) -> int:
        return self.__delete(key)


class ModelCache:
    """Fetches a model from an in-memory cache, instantiating it if it's missing."""

    def __init__(
        self,
        revalidate: bool = False,
        timeout: int | None = None,
        profiling: bool = False,
    ) -> None:
        """
        Args:
            revalidate: Resets TTL on cache hit. Useful to keep models in memory while active. Defaults to False.
            timeout: Maximum allowed time for model to load. Disabled if None. Defaults to None.
            profiling: Collects metrics for cache operations, adding slight overhead. Defaults to False.
        """

        plugins = []

        if profiling:
            plugins.append(TimingPlugin())

        self.should_revalidate = revalidate

        self.cache = UnloadingMemoryCache(timeout=timeout, plugins=plugins, namespace=None)

    async def get(
        self, model_name: str, model_type: ModelType, model_task: ModelTask, **model_kwargs: Any
    ) -> InferenceModel:
        key = f"{model_name}{model_type}{model_task}"

        async with OptimisticLock(self.cache, key) as lock:
            model: InferenceModel | None = await self.cache.get(key)
            if model is None:
                log.debug(f"Cache miss for {model_task} {model_type} model '{model_name}'")
                model = from_model_type(model_name, model_type, model_task, **model_kwargs)
                await lock.cas(model, ttl=model_kwargs.get("ttl", None))
            elif self.should_revalidate:
                await self.revalidate(key, model_kwargs.get("ttl", None))
        return model

    async def get_profiling(self) -> dict[str, float] | None:
        if not has_profiling(self.cache):
            return None

        return self.cache.profiling

    async def revalidate(self, key: str, ttl: int | None) -> None:
        if ttl is not None and key in self.cache._handlers:
            await self.cache.expire(key, ttl)
