#!/usr/bin/env bash
set -euo pipefail

host="${IMMICH_ML_URL:-http://127.0.0.1:3003}"
image_root="${1:-/Volumes/SKHynix/Music}"
model="${CLIP_MODEL:-XLM-Roberta-Large-ViT-H-14__frozen_laion5b_s13b_b90k}"
count="${COUNT:-8}"

i=0
find "$image_root" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -print |
  sed -n "1,${count}p" |
  while IFS= read -r file; do
    i=$((i + 1))
    out="$(mktemp)"
    metrics="$(curl -sS --max-time 240 -o "$out" -w 'http=%{http_code}\ttime=%{time_total}s\tsize=%{size_download}B' \
      -F "entries={\"clip\":{\"visual\":{\"modelName\":\"${model}\"}}}" \
      -F "image=@${file}" \
      "$host/predict")"
    printf '%02d\t%s\t%s\n' "$i" "$(basename "$file")" "$metrics"
    rm -f "$out"
  done
