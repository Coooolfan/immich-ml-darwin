#!/usr/bin/env bash
set -euo pipefail

host="${IMMICH_ML_URL:-http://127.0.0.1:3003}"
image_root="${1:-/Volumes/SKHynix/Music}"
model="${FACE_MODEL:-antelopev2}"
count="${COUNT:-8}"

i=0
find "$image_root" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -print |
  sed -n "1,${count}p" |
  while IFS= read -r file; do
    i=$((i + 1))
    out="$(mktemp)"
    metrics="$(curl -sS --max-time 240 -o "$out" -w 'http=%{http_code}\ttime=%{time_total}s\tsize=%{size_download}B' \
      -F "entries={\"facial-recognition\":{\"detection\":{\"modelName\":\"${model}\",\"options\":{\"minScore\":0.3}},\"recognition\":{\"modelName\":\"${model}\"}}}" \
      -F "image=@${file}" \
      "$host/predict")"
    faces="$(python3 - "$out" <<'PY'
import json
import sys

try:
    data = json.load(open(sys.argv[1]))
    faces = data.get("facial-recognition")
    print(len(faces) if isinstance(faces, list) else "NA")
except Exception:
    print("ERR")
PY
)"
    printf '%02d\t%s\t%s\tfaces=%s\n' "$i" "$(basename "$file")" "$metrics" "$faces"
    rm -f "$out"
  done
