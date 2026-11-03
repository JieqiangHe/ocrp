#!/bin/bash
# usage: ocrp-stage.sh <ocrp_repo> <staging_dir>
# Writes a plugin copy. Does not modify the repo. The repo's index.html must already
# prefer window.tbtools.ai inside ask(); this script only localises pdf.js for file://.
set -e
src=$(cd "$1" && pwd)
st=$2
a=$(cd "$(dirname "$0")/../assets" && pwd)
mkdir -p "$st/vendor"
cp "$a/tbtools-ai.json" "$st/"
curl -fsSL -o "$st/vendor/pdf.min.js" https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.min.js
curl -fsSL -o "$st/vendor/pdf.worker.min.js" https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js
curl -fsSL -o "$st/vendor/pdfjs-LICENSE" https://raw.githubusercontent.com/mozilla/pdf.js/v3.11.174/LICENSE
python3 - "$src/index.html" "$st/index.html" << 'PY'
import pathlib, sys
src, dst = sys.argv[1:]
h = pathlib.Path(src).read_text()
a = "https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.min.js"
b = "https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js"
if a not in h or b not in h:
    raise SystemExit("pdf.js CDN urls not found; stage script is out of date")
h = h.replace(a, "vendor/pdf.min.js", 1).replace(b, "vendor/pdf.worker.min.js", 1)
pathlib.Path(dst).write_text(h)
PY
echo "$st"
