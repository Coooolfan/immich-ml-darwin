# immich-ml-darwin

这是一个非官方的 Immich machine-learning 服务 macOS / Apple Silicon 调优版本。

这个仓库只包含上游 Immich 的 `machine-learning` 组件，保持 Immich ML HTTP API 兼容，同时增加一些直接在 Mac 上运行 ML 服务时更实用的运行时控制。

英文说明见 [README.en.md](README.en.md)。

## 默认行为

- OCR 默认使用 `CPUExecutionProvider`。
- 人脸识别默认保留 `CoreMLExecutionProvider,CPUExecutionProvider`。
- CLIP 和其他模型默认保持上游自动 provider 选择，除非显式配置。
- `CoreMLExecutionProvider` 的 package/cache 加载失败时，会自动重试一次 CPU。
- `scripts/start-darwin.sh` 默认设置 `MACHINE_LEARNING_MODEL_TTL=0`，让服务和模型常驻。
- 每次 `/predict` 请求、单个模型推理、模型首次加载都会记录耗时日志。

## 安装和启动

安装依赖：

```bash
uv sync --extra cpu
```

启动服务：

```bash
scripts/start-darwin.sh
```

默认服务地址是 `http://0.0.0.0:3003`。

## 配置

常用环境变量：

```bash
MACHINE_LEARNING_CACHE_FOLDER=/Volumes/SKHynix/immich-ml-cache
MACHINE_LEARNING_MODEL_TTL=0
MACHINE_LEARNING_MODEL_TTL_CLIP=0
MACHINE_LEARNING_MODEL_TTL_FACIAL_RECOGNITION=0
MACHINE_LEARNING_MODEL_TTL_OCR=0
MACHINE_LEARNING_PROVIDERS__OCR=CPUExecutionProvider
MACHINE_LEARNING_PROVIDERS__FACIAL_RECOGNITION=CoreMLExecutionProvider,CPUExecutionProvider
MACHINE_LEARNING_COREML_RETRY_CPU_ON_FAILURE=true
IMMICH_LOG_LEVEL=debug
IMMICH_HOST=0.0.0.0
IMMICH_PORT=3003
```

`MACHINE_LEARNING_MODEL_TTL` 是默认模型内存 TTL，单位秒，`<= 0` 表示不自动卸载。三个分类 TTL 可以单独覆盖默认值：

```bash
MACHINE_LEARNING_MODEL_TTL_CLIP=300
MACHINE_LEARNING_MODEL_TTL_FACIAL_RECOGNITION=120
MACHINE_LEARNING_MODEL_TTL_OCR=60
```

模型超过对应 TTL 后会从内存卸载；如果过期时仍在推理，会等当前推理结束后卸载。后续新请求会重新加载模型。

Provider 配置使用逗号分隔的 ONNX Runtime provider 列表。更具体的配置优先级更高：

```bash
MACHINE_LEARNING_PROVIDERS__CLIP_TEXTUAL=CPUExecutionProvider
MACHINE_LEARNING_PROVIDERS__CLIP_VISUAL=CPUExecutionProvider
MACHINE_LEARNING_PROVIDERS__CLIP=CPUExecutionProvider
MACHINE_LEARNING_PROVIDERS__OCR_DETECTION=CPUExecutionProvider
MACHINE_LEARNING_PROVIDERS__OCR_RECOGNITION=CPUExecutionProvider
MACHINE_LEARNING_PROVIDERS__FACIAL_RECOGNITION_DETECTION=CoreMLExecutionProvider,CPUExecutionProvider
MACHINE_LEARNING_PROVIDERS__FACIAL_RECOGNITION_RECOGNITION=CoreMLExecutionProvider,CPUExecutionProvider
MACHINE_LEARNING_PROVIDERS__DEFAULT=CoreMLExecutionProvider,CPUExecutionProvider
```

## 上游来源

这个仓库从 Immich 上游仓库的 `machine-learning` 目录拆分而来。具体 commit 和版本见 [UPSTREAM.md](UPSTREAM.md)。

## 许可说明

本仓库继承上游 Immich machine-learning 代码，使用 GNU Affero General Public License v3.0，详见 [LICENSE](LICENSE)。

第三方模型和依赖仍受各自许可证约束。尤其是 InsightFace 模型的再分发和商业使用，需要遵守 InsightFace 的许可条款。
