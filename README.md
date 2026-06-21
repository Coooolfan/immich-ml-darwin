# immich-ml-darwin

Unofficial Immich machine-learning service tuning for macOS and Apple Silicon.

This repository contains only the upstream Immich `machine-learning` component. It keeps the Immich ML HTTP API compatible while adding small runtime controls that are useful when running the ML service directly on a Mac.

## Defaults

- OCR runs on `CPUExecutionProvider` by default.
- Facial recognition keeps `CoreMLExecutionProvider,CPUExecutionProvider`.
- CLIP and other models keep upstream automatic provider selection unless configured.
- `CoreMLExecutionProvider` package/cache load failures are retried once with CPU.
- `scripts/start-darwin.sh` defaults `MACHINE_LEARNING_MODEL_TTL=0` so the service stays resident.

## Setup

Install dependencies:

```bash
uv sync --extra cpu
```

Start the service:

```bash
scripts/start-darwin.sh
```

The default URL is `http://0.0.0.0:3003`.

## Configuration

Common environment variables:

```bash
MACHINE_LEARNING_CACHE_FOLDER=/Volumes/SKHynix/immich-ml-cache
MACHINE_LEARNING_MODEL_TTL=0
MACHINE_LEARNING_PROVIDERS__OCR=CPUExecutionProvider
MACHINE_LEARNING_PROVIDERS__FACIAL_RECOGNITION=CoreMLExecutionProvider,CPUExecutionProvider
MACHINE_LEARNING_COREML_RETRY_CPU_ON_FAILURE=true
IMMICH_LOG_LEVEL=debug
IMMICH_HOST=0.0.0.0
IMMICH_PORT=3003
```

Provider profiles are comma-separated ONNX Runtime provider lists. More specific profiles win over broader profiles:

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

## Benchmarks

The benchmark scripts call the running HTTP service:

```bash
scripts/bench-face.sh /Volumes/SKHynix/Music
scripts/bench-ocr.sh /Volumes/SKHynix/Music
scripts/bench-clip-visual.sh /Volumes/SKHynix/Music
```

Useful overrides:

```bash
COUNT=20 FACE_MODEL=antelopev2 scripts/bench-face.sh /Volumes/SKHynix/Music
OCR_MODEL=PP-OCRv5_mobile scripts/bench-ocr.sh /Volumes/SKHynix/Music
CLIP_MODEL=XLM-Roberta-Large-ViT-H-14__frozen_laion5b_s13b_b90k scripts/bench-clip-visual.sh /Volumes/SKHynix/Music
```

## Upstream

See `UPSTREAM.md` for the upstream Immich commit and path this repository was split from.

## License Notes

This repository inherits the upstream Immich machine-learning code and its third-party model constraints. In particular, InsightFace model redistribution and commercial use are subject to InsightFace licensing terms.
