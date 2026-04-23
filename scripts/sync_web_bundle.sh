#!/bin/zsh
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEFAULT_SOURCE="$PROJECT_ROOT/../SAVI /index.html"
SOURCE_PATH="${1:-${SAVI_WEB_SOURCE:-$DEFAULT_SOURCE}}"
DEST_PATH="${2:-$PROJECT_ROOT/SAVI/Resources/index.html}"

if [[ ! -f "$SOURCE_PATH" ]]; then
  echo "warning: SAVI web source not found at: $SOURCE_PATH" >&2
  exit 0
fi

mkdir -p "$(dirname "$DEST_PATH")"

if cmp -s "$SOURCE_PATH" "$DEST_PATH"; then
  echo "SAVI web bundle already in sync"
  exit 0
fi

cp "$SOURCE_PATH" "$DEST_PATH"
echo "Synced web bundle:"
echo "  source: $SOURCE_PATH"
echo "  dest:   $DEST_PATH"
