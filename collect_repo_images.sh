#!/usr/bin/env bash
set -euo pipefail

#######################################
# CONFIG
#######################################
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REPOS_DIR="$BASE_DIR/_repos"
OUTPUT_DIR="$BASE_DIR/all-images"
LOG_DIR="$BASE_DIR/logs"
STATE_FILE="$BASE_DIR/.repo_state.tsv"
JOBS="$(sysctl -n hw.ncpu 2>/dev/null || echo 4)"

mkdir -p "$REPOS_DIR" "$OUTPUT_DIR"/{4K,2K,Portrait,Other} "$LOG_DIR"

#######################################
# UTILS
#######################################
timestamp() { date +"%Y-%m-%dT%H:%M:%S"; }
log() { echo "[$(timestamp)] $1"; }

IM_CMD="$(command -v magick || command -v convert)"

#######################################
# IMAGE PROCESSOR (INLINE, NO EXPORT)
#######################################
process_image() {
  img="$1"

  read w h <<<"$($IM_CMD identify -format "%w %h" "$img" 2>/dev/null || echo "0 0")"

  if [ "$w" -ge 3840 ] || [ "$h" -ge 3840 ]; then
    bucket="4K"
  elif [ "$w" -ge 2560 ] || [ "$h" -ge 2560 ]; then
    bucket="2K"
  elif [ "$h" -gt "$w" ]; then
    bucket="Portrait"
  else
    bucket="Other"
  fi

  base="$(basename "$img")"
  target="$OUTPUT_DIR/$bucket/$base"

  if [ -f "$target" ]; then
    echo "SKIP"
    return
  fi

  $IM_CMD "$img" -strip "$target"
  echo "OK"
}

#######################################
# INPUT
#######################################
REPO_URL="${1:-}"
[ -z "$REPO_URL" ] && echo "Usage: ./collect_repo_images.sh <repo-url>" && exit 1

REPO_NAME="$(basename "$REPO_URL" .git)"
REPO_PATH="$REPOS_DIR/$REPO_NAME"
REPO_LOG="$LOG_DIR/$REPO_NAME.log"

log "Processing repo: $REPO_NAME" | tee "$REPO_LOG"

#######################################
# CLONE / UPDATE
#######################################
if [ -d "$REPO_PATH/.git" ]; then
  git -C "$REPO_PATH" fetch --quiet
else
  git clone --quiet "$REPO_URL" "$REPO_PATH"
fi

cd "$REPO_PATH"

LATEST_COMMIT="$(git rev-parse HEAD)"

PREV_COMMIT=""
[ -f "$STATE_FILE" ] && PREV_COMMIT="$(grep "^$REPO_URL" "$STATE_FILE" | awk '{print $2}')"

if [ "$LATEST_COMMIT" = "$PREV_COMMIT" ]; then
  log "No new commits. Skipping." | tee -a "$REPO_LOG"
  exit 0
fi

#######################################
# FIND + PROCESS IMAGES (SAFE)
#######################################
FOUND=0
OK=0
SKIP=0

find . -type f \( \
  -iname "*.jpg" -o \
  -iname "*.jpeg" -o \
  -iname "*.png" -o \
  -iname "*.webp" \
\) -print0 |
while IFS= read -r -d '' img; do
  FOUND=$((FOUND+1))

  result="$(process_image "$img")"
  if [ "$result" = "OK" ]; then
    OK=$((OK+1))
  else
    SKIP=$((SKIP+1))
  fi
done

#######################################
# LOGGING
#######################################
{
  echo "--------------------------------------"
  echo "Repo:              $REPO_URL"
  echo "Commit:            $LATEST_COMMIT"
  echo "Images found:      $FOUND"
  echo "Processed:         $OK"
  echo "Skipped:           $SKIP"
  echo "Finished:          $(timestamp)"
  echo
} >> "$REPO_LOG"

grep -v "^$REPO_URL" "$STATE_FILE" 2>/dev/null > "$STATE_FILE.tmp" || true
echo "$REPO_URL $LATEST_COMMIT $(timestamp)" >> "$STATE_FILE.tmp"
mv "$STATE_FILE.tmp" "$STATE_FILE"

echo "$REPO_NAME,$LATEST_COMMIT,$FOUND,$OK,$SKIP" >> "$LOG_DIR/summary.csv"

log "Done." | tee -a "$REPO_LOG"
