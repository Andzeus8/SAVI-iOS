#!/bin/zsh
set -euo pipefail

MAIN_BUNDLE_ID="com.savi.app"
TEST_BUNDLE_ID="com.altatecrd.savi.personaldebug"
MAIN_APP_GROUP="group.com.savi.shared"
SIMULATOR_ID="${SIMULATOR_ID:-}"
BACKUP_ROOT="${SAVI_TEST_BACKUP_ROOT:-/Users/guest1/Desktop/SAVI_QA/test-data-backups}"

usage() {
  cat <<'EOF'
Usage: scripts/savi-clone-main-to-test-sim.sh [--simulator-id UDID]

Copies simulator data from main SAVI into SAVI Test so the two installed apps
look the same during QA.

Source:
  com.savi.app / group.com.savi.shared / native

Destination:
  com.altatecrd.savi.personaldebug / Documents/SAVI-native

Before overwriting Test data, the script creates a timestamped backup under:
  /Users/guest1/Desktop/SAVI_QA/test-data-backups/

Environment:
  SIMULATOR_ID           Optional booted simulator UDID override.
  SAVI_TEST_BACKUP_ROOT  Optional backup root override.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --simulator-id)
      SIMULATOR_ID="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$SIMULATOR_ID" ]]; then
  SIMULATOR_ID="$(xcrun simctl list devices booted | awk -F'[()]' '/Booted/{print $2; exit}')"
fi

if [[ -z "$SIMULATOR_ID" ]]; then
  echo "No booted simulator found. Boot one first, or pass --simulator-id UDID." >&2
  exit 1
fi

main_group="$(xcrun simctl get_app_container "$SIMULATOR_ID" "$MAIN_BUNDLE_ID" "$MAIN_APP_GROUP")"
main_data="$(xcrun simctl get_app_container "$SIMULATOR_ID" "$MAIN_BUNDLE_ID" data)"
test_data="$(xcrun simctl get_app_container "$SIMULATOR_ID" "$TEST_BUNDLE_ID" data)"

source_native="$main_group/native"
source_library="$source_native/savi_native_library.json"
dest_native="$test_data/Documents/SAVI-native"
dest_library="$dest_native/savi_native_library.json"

if [[ ! -f "$source_library" ]]; then
  echo "Main SAVI native library not found:" >&2
  echo "  $source_library" >&2
  exit 1
fi

timestamp="$(date +%Y%m%d-%H%M%S)"
backup_dir="$BACKUP_ROOT/$timestamp"
mkdir -p "$backup_dir"

if [[ -e "$dest_native" ]]; then
  ditto "$dest_native" "$backup_dir/SAVI-native-before"
fi

source_cache="$main_data/Library/Caches/savi-remote-thumbnails"
dest_cache="$test_data/Library/Caches/savi-remote-thumbnails"
if [[ -e "$dest_cache" ]]; then
  ditto "$dest_cache" "$backup_dir/savi-remote-thumbnails-before"
fi

mkdir -p "$(dirname "$dest_native")"
rm -rf "$dest_native"
ditto "$source_native" "$dest_native"

if [[ -d "$source_cache" ]]; then
  mkdir -p "$(dirname "$dest_cache")"
  rm -rf "$dest_cache"
  ditto "$source_cache" "$dest_cache"
fi

python3 - "$source_library" "$dest_library" <<'PY'
import json
import pathlib
import sys

for label, raw_path in [("Main", sys.argv[1]), ("SAVI Test", sys.argv[2])]:
    path = pathlib.Path(raw_path)
    data = json.loads(path.read_text())
    prefs = data.get("prefs", {})
    widgets = prefs.get("homeWidgets", [])
    print(f"{label}: {len(data.get('folders', []))} folders, {len(data.get('items', []))} items, {len(data.get('assets', []))} assets")
    print(f"  folderViewMode={prefs.get('folderViewMode')} homeFolderMode={prefs.get('homeFolderMode')} homeLayoutMode={prefs.get('homeLayoutMode')}")
    print(f"  widgets={[(w.get('kind'), w.get('size'), w.get('isHidden')) for w in widgets]}")
PY

echo
echo "Cloned main SAVI simulator data into SAVI Test."
echo "Simulator: $SIMULATOR_ID"
echo "Backup:    $backup_dir"
echo "Source:    $source_native"
echo "Dest:      $dest_native"
