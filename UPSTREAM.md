# Upstream

This repository contains only the Immich machine-learning service.

- Upstream repository: `immich-app/immich`
- Upstream path: `machine-learning`
- Base commit: `95e57a24cb11b4bcff39b770ae2d81443434c210`
- Base version: `v2.7.5`

Local changes are intended to stay limited to macOS and Apple Silicon runtime behavior:

- provider selection logs
- per-task provider preferences
- OCR defaulting to CPU
- CoreML cache/load failure fallback to CPU
- local start and benchmark scripts
