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

SOURCE_DIR="$(cd "$(dirname "$SOURCE_PATH")" && pwd)"
VENDOR_DIR="$SOURCE_DIR/vendor"

mkdir -p "$(dirname "$DEST_PATH")"
cp "$SOURCE_PATH" "$DEST_PATH"

if [[ -f "$VENDOR_DIR/react.production.min.js" && -f "$VENDOR_DIR/react-dom.production.min.js" && -f "$VENDOR_DIR/babel.min.js" ]]; then
  python3 - "$DEST_PATH" "$VENDOR_DIR" "$PROJECT_ROOT/scripts/transpile_jsx.swift" <<'PY'
from pathlib import Path
import base64
import subprocess
import tempfile
import sys

dest = Path(sys.argv[1])
vendor = Path(sys.argv[2])
transpiler = Path(sys.argv[3])
text = dest.read_text()
replacements = {
    '<script src="./vendor/react.production.min.js"></script>': '<script src="data:text/javascript;base64,' + base64.b64encode((vendor / 'react.production.min.js').read_bytes()).decode() + '"></script>',
    '<script src="./vendor/react-dom.production.min.js"></script>': '<script src="data:text/javascript;base64,' + base64.b64encode((vendor / 'react-dom.production.min.js').read_bytes()).decode() + '"></script>',
}
for old, new in replacements.items():
    text = text.replace(old, new)

start_marker = '<script type="text/babel" data-presets="env,react">'
end_marker = '</script>'
text = text.replace('<script src="./vendor/babel.min.js"></script>\n', '', 1)
start = text.find(start_marker)
if start != -1:
    body_start = start + len(start_marker)
    end = text.find(end_marker, body_start)
    jsx = text[body_start:end]
    with tempfile.TemporaryDirectory() as tmp:
        tmp_path = Path(tmp)
        jsx_path = tmp_path / "app.jsx"
        jsx_path.write_text(jsx)
        process = subprocess.run(
            ["xcrun", "--sdk", "macosx", "swift", str(transpiler), str(jsx_path), str(vendor / "babel.min.js")],
            capture_output=True,
            text=True,
        )
        if process.returncode != 0:
            raise SystemExit(process.stderr or process.stdout or f"Swift transpiler failed with {process.returncode}")
        transpiled = process.stdout

    wrapped = (
        "window.__saviBundleStarted = true;\n"
        "try {\n"
        + transpiled +
        "\nwindow.__saviBundleExecuted = true;\n"
        "} catch (error) {\n"
        "  window.__saviBundleError = error && error.stack ? error.stack : String(error);\n"
        "  console.error('SAVI bundle runtime error', error && error.stack ? error.stack : String(error));\n"
        "  throw error;\n"
        "}\n"
    )
    text = text[:start] + "<script>\n" + wrapped + "\n</script>" + text[end + len(end_marker):]

dest.write_text(text)
PY
fi

echo "Synced web bundle:"
echo "  source: $SOURCE_PATH"
echo "  dest:   $DEST_PATH"
