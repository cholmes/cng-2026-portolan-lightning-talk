#!/usr/bin/env bash
# Rebuild media/*.mp4 from the raw screen recordings.
#
# The raws are not in the repo (they are hundreds of megabytes of GIF); point
# SRC at wherever they live.
#
# Every clip is cut to the 15 seconds its slide gets. Nothing is ever cropped
# horizontally: each clip keeps its full width, and the slide shows it full
# width with whatever slack is left over as a band at the bottom. The two tall
# recordings are cropped vertically to get near 16:9, which is also what makes
# their text big enough to read from the back of the room.
set -euo pipefail

SRC="${1:-$HOME/Documents/Portolan Lightning Talk}"
OUT="$(cd "$(dirname "$0")/.." && pwd)/media"
mkdir -p "$OUT"

# H.264 needs even dimensions and several of the raws are odd by one pixel.
EVEN='crop=trunc(iw/2)*2:trunc(ih/2)*2'

ENC=(-c:v libx264 -profile:v high -pix_fmt yuv420p -crf 24 -preset slow -movflags +faststart -an)

# stac-geoparquet search — drop the first 3 s of dead air, keep 15 s
ffmpeg -v error -y -ss 3 -t 15 -i "$SRC/cng-s2-portolan.gif" \
  -vf "fps=20,$EVEN" "${ENC[@]}" "$OUT/s2-search.mp4"

# Portolan browser — first 15 s
ffmpeg -v error -y -t 15 -i "$SRC/data-browser.gif" \
  -vf "fps=20,$EVEN" "${ENC[@]}" "$OUT/data-browser.mp4"

# Registry — first 15 s
ffmpeg -v error -y -t 15 -i "$SRC/port-registry.gif" \
  -vf "fps=20,$EVEN" "${ENC[@]}" "$OUT/registry.mp4"

# FIRMS explorer — reversed, so it opens on the 20-year global view and ends
# zoomed into single detections. Trim first, so the cut lands at the far end.
ffmpeg -v error -y -t 15 -i "$SRC/firms-cng2.gif" \
  -vf "fps=20,$EVEN,reverse" "${ENC[@]}" "$OUT/firms-explorer.mp4"

# Finland data-centre demo — all 23.3 s sped up into 15 s
ffmpeg -v error -y -i "$SRC/finland-demo.gif" \
  -vf "fps=20,$EVEN,setpts=PTS/1.552" "${ENC[@]}" "$OUT/finland-demo.mp4"

# agents.md chat — 2 s holding on the prompt, then 13 s of the answer.
# The recording starts mid-answer, so the prompt is a still card bolted on
# front. Cropping to the top 640 rows drops the message composer.
ffmpeg -v error -y -loop 1 -t 2 -i "$SRC/tulip-chat-prompt.webp" \
  -f lavfi -t 2 -i "color=c=0xfcfcfa:s=1138x640:r=20" \
  -filter_complex "[0:v]scale=1086:-2[p];[1:v][p]overlay=(W-w)/2:(H-h)/2,fps=20,format=yuv420p[v]" \
  -map "[v]" "${ENC[@]}" "$OUT/.chat-a.mp4"
ffmpeg -v error -y -t 13 -i "$SRC/crop-chat.webm" \
  -vf "fps=20,crop=1138:640:0:0" "${ENC[@]}" "$OUT/.chat-b.mp4"
printf "file '%s'\nfile '%s'\n" "$OUT/.chat-a.mp4" "$OUT/.chat-b.mp4" > "$OUT/.chat.txt"
ffmpeg -v error -y -f concat -safe 0 -i "$OUT/.chat.txt" -c copy "$OUT/tulip-chat.mp4"

# Catalog-building demo — four beats in fifteen seconds: the prompt, the agent
# working, the published catalog on Source Cooperative, and the same catalog
# in the browser. The prompt is typed out in real time over 16 s, so that part
# runs at 5.3x. The browser beat starts at 60 s rather than 57 s: the three
# seconds before it are an empty desktop and a loading spinner.
#   crop: vertical only. The terminal fills the frame top-down, so that beat
#   keeps the top 818 rows; the web pages are cropped about their middle.
ffmpeg -v error -y -t 16 -i "$SRC/portolan-demo-one.mp4" \
  -vf "fps=20,crop=1454:818:0:0,setpts=PTS/5.333" "${ENC[@]}" "$OUT/.demo-a.mp4"
ffmpeg -v error -y -ss 46 -t 8 -i "$SRC/portolan-demo-one.mp4" \
  -vf "fps=20,crop=1454:818:0:150,setpts=PTS/2" "${ENC[@]}" "$OUT/.demo-b.mp4"
ffmpeg -v error -y -ss 60 -t 13 -i "$SRC/portolan-demo-one.mp4" \
  -vf "fps=20,crop=1454:818:0:150,setpts=PTS/1.625" "${ENC[@]}" "$OUT/.demo-c.mp4"
printf "file '%s'\nfile '%s'\nfile '%s'\n" \
  "$OUT/.demo-a.mp4" "$OUT/.demo-b.mp4" "$OUT/.demo-c.mp4" > "$OUT/.demo.txt"
ffmpeg -v error -y -f concat -safe 0 -i "$OUT/.demo.txt" -c copy "$OUT/catalog-demo.mp4"

rm -f "$OUT"/.chat-*.mp4 "$OUT"/.demo-*.mp4 "$OUT"/.chat.txt "$OUT"/.demo.txt

for f in "$OUT"/*.mp4; do
  dims=$(ffprobe -v error -select_streams v -show_entries stream=width,height -of csv=p=0 "$f")
  w=${dims%%,*}; h=${dims##*,}
  printf '%-22s %6.2fs  %sx%s  %s  %s\n' "$(basename "$f")" \
    "$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$f")" \
    "$w" "$h" "$(echo "scale=3; $w/$h" | bc)" "$(du -h "$f" | cut -f1)"
done
echo "(16:9 is 1.778)"
