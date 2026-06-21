#!/usr/bin/env bash
set -euo pipefail

host="${IMMICH_ML_URL:-http://127.0.0.1:3003}"
image_root="${1:-/Volumes/SKHynix/Music}"
model="${OCR_MODEL:-PP-OCRv5_mobile}"
count="${COUNT:-8}"

i=0
find "$image_root" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -print |
  sed -n "1,${count}p" |
  while IFS= read -r file; do
    i=$((i + 1))
    out="$(mktemp)"
    metrics="$(curl -sS --max-time 300 -o "$out" -w 'http=%{http_code}\ttime=%{time_total}s\tsize=%{size_download}B' \
      -F "entries={\"ocr\":{\"detection\":{\"modelName\":\"${model}\"},\"recognition\":{\"modelName\":\"${model}\"}}}" \
      -F "image=@${file}" \
      "$host/predict")"
    texts="$(python3 - "$out" <<'PY'
import json
import sys

try:
    data = json.load(open(sys.argv[1]))
    ocr = data.get("ocr")
    text = ocr.get("text") if isinstance(ocr, dict) else None
    print(len(text) if isinstance(text, list) else "NA")
except Exception:
    print("ERR")
PY
)"
    printf '%02d\t%s\t%s\ttexts=%s\n' "$i" "$(basename "$file")" "$metrics" "$texts"
    rm -f "$out"
  done
