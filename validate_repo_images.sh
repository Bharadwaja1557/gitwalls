#!/bin/zsh

set -e

BASE_DIR="/Users/mb/Developer/gitwalls"
REPO_DIR="$BASE_DIR/_repos"

export PATH="/bin:/usr/bin:/usr/sbin:/sbin:/opt/homebrew/bin"

if [[ -z "$1" ]]; then
  echo "Usage: ./validate_repo_images.sh <github-repo-url>"
  exit 1
fi

REPO_URL="$1"
REPO_NAME=$(basename "$REPO_URL" .git)
CLONE_PATH="$REPO_DIR/$REPO_NAME"

mkdir -p "$REPO_DIR"

# Clone or update
if [[ ! -d "$CLONE_PATH/.git" ]]; then
  echo "Cloning $REPO_URL"
  git clone "$REPO_URL" "$CLONE_PATH"
else
  echo "Updating $REPO_NAME"
  cd "$CLONE_PATH"
  git fetch origin
fi

cd "$CLONE_PATH"

DEFAULT_BRANCH=$(git remote show origin | awk '/HEAD branch/ {print $NF}')
git checkout "$DEFAULT_BRANCH" >/dev/null 2>&1

echo
echo "Repository: $REPO_NAME"
echo "Branch:     $DEFAULT_BRANCH"
echo "Location:   $CLONE_PATH"
echo "--------------------------------------"

# Find images (NULL-safe)
IMAGE_LIST=$(find . -type f \( \
  -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.bmp" -o -iname "*.tiff" \
\))

TOTAL=$(echo "$IMAGE_LIST" | wc -l | tr -d ' ')

if [[ "$TOTAL" -eq 0 ]]; then
  echo "❌ No images found in this repo."
  exit 0
fi

echo "✅ Total images found: $TOTAL"
echo

# Extension stats
echo "By extension:"
echo "$IMAGE_LIST" | sed 's/.*\.//' | tr 'A-Z' 'a-z' | sort | uniq -c | sed 's/^/  /'
echo

# Depth stats
echo "By folder depth (from repo root):"
echo "$IMAGE_LIST" | awk -F'/' '{print NF-1}' | sort | uniq -c | sed 's/^/  /'
echo

# Sample paths
echo "Sample image paths:"
echo "$IMAGE_LIST" | head -10 | sed 's/^/  /'

echo
echo "Validation complete."

