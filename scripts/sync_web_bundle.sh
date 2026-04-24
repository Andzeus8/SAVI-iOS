#!/bin/zsh
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEFAULT_SOURCE="$PROJECT_ROOT/../SAVI /index.html"
SOURCE_PATH="${1:-${SAVI_WEB_SOURCE:-$DEFAULT_SOURCE}}"
DEST_PATH="${2:-$PROJECT_ROOT/SAVI/Resources/index.html}"
SOURCE_DIR="$(cd "$(dirname "$SOURCE_PATH")" && pwd)"
VENDOR_DIR="$SOURCE_DIR/vendor"

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

if [[ -f "$VENDOR_DIR/react.production.min.js" && -f "$VENDOR_DIR/react-dom.production.min.js" && -f "$VENDOR_DIR/babel.min.js" ]]; then
  python3 - "$DEST_PATH" "$VENDOR_DIR" <<'PY'
from pathlib import Path
import sys

dest = Path(sys.argv[1])
vendor = Path(sys.argv[2])
text = dest.read_text()
replacements = {
    '<script src="./vendor/react.production.min.js"></script>': f"<script>\n{(vendor / 'react.production.min.js').read_text()}\n</script>",
    '<script src="./vendor/react-dom.production.min.js"></script>': f"<script>\n{(vendor / 'react-dom.production.min.js').read_text()}\n</script>",
    '<script src="./vendor/babel.min.js"></script>': f"<script>\n{(vendor / 'babel.min.js').read_text()}\n</script>",
}
for old, new in replacements.items():
    text = text.replace(old, new)
dest.write_text(text)
PY
fi

echo "Synced web bundle:"
echo "  source: $SOURCE_PATH"
echo "  dest:   $DEST_PATH"
