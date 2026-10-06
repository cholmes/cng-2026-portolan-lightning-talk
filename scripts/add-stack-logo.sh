#!/usr/bin/env bash
# Install a dependency logo for the slide 12 stack diagram.
#
#   ./scripts/add-stack-logo.sh <name> <source-file>
#
# Trims the surrounding whitespace (so every logo sits tight in its node
# regardless of how much padding the source carried), drops the result in
# images/stack/<name>.png, and prints the aspect ratio and whether the logo
# brings its own background — the two things the CSS needs to know.
#
# SVG sources are copied through untouched; they have no bitmap margin to trim.
set -euo pipefail

NAME="${1:?usage: add-stack-logo.sh <name> <source-file>}"
SRC="${2:?usage: add-stack-logo.sh <name> <source-file>}"
OUT="$(cd "$(dirname "$0")/.." && pwd)/images/stack"
mkdir -p "$OUT"

if [[ "$SRC" == *.svg ]]; then
  cp "$SRC" "$OUT/$NAME.svg"
  echo "$NAME.svg  (copied as-is)"
  exit 0
fi

python3 - "$NAME" "$SRC" "$OUT" <<'PY'
import sys
from PIL import Image

name, src, out = sys.argv[1], sys.argv[2], sys.argv[3]
im = Image.open(src).convert('RGBA')
px, (w, h) = im.load(), im.size

def is_bg(p):
    r, g, b, a = p
    return a <= 20 or (r > 240 and g > 240 and b > 240)

minx, miny, maxx, maxy = w, h, -1, -1
for y in range(h):
    for x in range(w):
        if not is_bg(px[x, y]):
            minx, maxx = min(minx, x), max(maxx, x)
            miny, maxy = min(miny, y), max(maxy, y)

if maxx < 0:
    raise SystemExit(f'{name}: the whole image reads as background')

im.crop((minx, miny, maxx + 1, maxy + 1)).save(f'{out}/{name}.png')
cw, ch = maxx + 1 - minx, maxy + 1 - miny

# A logo that still fills its own corners after trimming carries a background
# of its own, and wants the .block class so it reaches the node's edges.
corners = [px[minx, miny], px[maxx, miny], px[minx, maxy], px[maxx, maxy]]
block = all(not is_bg(c) for c in corners)
print(f'{name}.png  {cw}x{ch}  ratio {cw/ch:.2f}  '
      f'{"has its own background — use class=\"dep logo block\"" if block else "transparent/white edges"}')
PY
