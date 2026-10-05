#!/usr/bin/env bash
# Rebuild media/*.mp4 from the raw screen recordings.
#
# The raws are not in the repo (they are hundreds of megabytes of GIF); point
# SRC at wherever they live. Each clip is cut to the 15 seconds its slide gets.
set -euo pipefail

SRC="${1:-$HOME/Documents/Portolan Lightning Talk}"
OUT="$(cd "$(dirname "$0")/.." && pwd)/media"
mkdir -p "$OUT"

ENC=(-c:v libx264 -profile:v high -pix_fmt yuv420p -crf 24 -preset slow -movflags +faststart -an)

# stac-geoparquet search — drop the first 3 s of dead air, keep 15 s
ffmpeg -v error -y -ss 3 -t 15 -i "$SRC/cng-s2-portolan.gif" \
  -vf "fps=20,scale=1148:-2" "${ENC[@]}" "$OUT/s2-search.mp4"

# Portolan browser — first 15 s
ffmpeg -v error -y -t 15 -i "$SRC/data-browser.gif" \
  -vf "fps=20,scale=1308:-2" "${ENC[@]}" "$OUT/data-browser.mp4"

# Registry — first 15 s
ffmpeg -v error -y -t 15 -i "$SRC/port-registry.gif" \
  -vf "fps=20,scale=1240:-2" "${ENC[@]}" "$OUT/registry.mp4"

# FIRMS explorer — reversed, so it opens on the 20-year global view and ends
# zoomed into single detections. Trim first, so the cut lands at the far end.
ffmpeg -v error -y -t 15 -i "$SRC/firms-cng2.gif" \
  -vf "fps=20,scale=1246:-2,reverse" "${ENC[@]}" "$OUT/firms-explorer.mp4"

# Finland data-centre demo — all 23.3 s sped up into 15 s
ffmpeg -v error -y -i "$SRC/finland-demo.gif" \
  -vf "fps=20,scale=1250:-2,setpts=PTS/1.552" "${ENC[@]}" "$OUT/finland-demo.mp4"

# agents.md chat — 2 s holding on the prompt, then 13 s of the answer.
# The recording starts mid-answer, so the prompt is a still card bolted on front.
ffmpeg -v error -y -loop 1 -t 2 -i "$SRC/tulip-chat-prompt.webp" \
  -f lavfi -t 2 -i "color=c=0xfcfcfa:s=1138x764:r=20" \
  -filter_complex "[0:v]scale=1086:-2[p];[1:v][p]overlay=(W-w)/2:(H-h)/2,fps=20,format=yuv420p[v]" \
  -map "[v]" "${ENC[@]}" "$OUT/.chat-a.mp4"
ffmpeg -v error -y -t 13 -i "$SRC/crop-chat.webm" \
  -vf "fps=20,scale=1138:-2" "${ENC[@]}" "$OUT/.chat-b.mp4"
printf "file '%s'\nfile '%s'\n" "$OUT/.chat-a.mp4" "$OUT/.chat-b.mp4" > "$OUT/.chat.txt"
ffmpeg -v error -y -f concat -safe 0 -i "$OUT/.chat.txt" -c copy "$OUT/tulip-chat.mp4"

# Catalog-building demo — the opening prompt, the agent working, then results.
# The prompt is typed out in real time over 10 s, which is most of the slide
# for one line of text, so that stretch runs at 2x and the rest at 1x.
ffmpeg -v error -y -t 10 -i "$SRC/portolan-demo-one.mp4" \
  -vf "fps=20,scale=1454:-2,setpts=PTS/2" "${ENC[@]}" "$OUT/.demo-a.mp4"
ffmpeg -v error -y -ss 10 -t 5 -i "$SRC/portolan-demo-one.mp4" \
  -vf "fps=20,scale=1454:-2" "${ENC[@]}" "$OUT/.demo-b.mp4"
ffmpeg -v error -y -ss 67.9 -i "$SRC/portolan-demo-one.mp4" \
  -vf "fps=20,scale=1454:-2" "${ENC[@]}" "$OUT/.demo-c.mp4"
printf "file '%s'\nfile '%s'\nfile '%s'\n" \
  "$OUT/.demo-a.mp4" "$OUT/.demo-b.mp4" "$OUT/.demo-c.mp4" > "$OUT/.demo.txt"
ffmpeg -v error -y -f concat -safe 0 -i "$OUT/.demo.txt" -c copy "$OUT/catalog-demo.mp4"

rm -f "$OUT"/.chat-*.mp4 "$OUT"/.demo-*.mp4 "$OUT"/.chat.txt "$OUT"/.demo.txt

for f in "$OUT"/*.mp4; do
  printf '%-34s %6.2fs  %s\n' "$(basename "$f")" \
    "$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$f")" \
    "$(du -h "$f" | cut -f1)"
done
