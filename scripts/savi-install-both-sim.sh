#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/SAVI.xcodeproj"
SCHEME="SAVI"
DEBUG_DERIVED_DATA="$ROOT/.DerivedData-sync-debug"
RELEASE_DERIVED_DATA="$ROOT/.DerivedData-sync-release"
DEBUG_BUNDLE_ID="com.altatecrd.savi.personaldebug"
RELEASE_BUNDLE_ID="com.savi.app"
LAUNCH_APPS=1
SIMULATOR_ID="${SIMULATOR_ID:-}"

usage() {
  cat <<'EOF'
Usage: scripts/savi-install-both-sim.sh [--simulator-id UDID] [--no-launch]

Builds and installs both SAVI simulator channels from the same source tree:
  Debug   -> SAVI Test -> com.altatecrd.savi.personaldebug
  Release -> SAVI      -> com.savi.app

Environment:
  SIMULATOR_ID  Optional booted simulator UDID override.
  SAVI_XCODEBUILD_VERBOSE=1  Show full xcodebuild output.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --simulator-id)
      SIMULATOR_ID="${2:-}"
      shift 2
      ;;
    --no-launch)
      LAUNCH_APPS=0
      shift
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

app_path() {
  local derived_data="$1"
  local configuration="$2"
  find "$derived_data/Build/Products/${configuration}-iphonesimulator" -maxdepth 1 -name "*.app" -print -quit
}

bundle_id_for_app() {
  local app="$1"
  /usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$app/Info.plist"
}

build_install_channel() {
  local label="$1"
  local configuration="$2"
  local derived_data="$3"
  local expected_bundle_id="$4"
  local quiet_args=()

  if [[ "${SAVI_XCODEBUILD_VERBOSE:-0}" != "1" ]]; then
    quiet_args=(-quiet)
  fi

  echo "==> Building $label ($configuration)"
  xcodebuild \
    "${quiet_args[@]}" \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$configuration" \
    -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
    -derivedDataPath "$derived_data" \
    ONLY_ACTIVE_ARCH=YES \
    COMPILER_INDEX_STORE_ENABLE=NO \
    build

  local app
  app="$(app_path "$derived_data" "$configuration")"
  if [[ -z "$app" || ! -d "$app" ]]; then
    echo "Could not find built app for $label in $derived_data" >&2
    exit 1
  fi

  local actual_bundle_id
  actual_bundle_id="$(bundle_id_for_app "$app")"
  if [[ "$actual_bundle_id" != "$expected_bundle_id" ]]; then
    echo "Bundle ID mismatch for $label:" >&2
    echo "  expected: $expected_bundle_id" >&2
    echo "  actual:   $actual_bundle_id" >&2
    echo "  app:      $app" >&2
    exit 1
  fi

  echo "==> Installing $label ($actual_bundle_id)"
  xcrun simctl install "$SIMULATOR_ID" "$app"

  if [[ "$LAUNCH_APPS" -eq 1 ]]; then
    echo "==> Launching $label ($actual_bundle_id)"
    xcrun simctl launch "$SIMULATOR_ID" "$actual_bundle_id" >/dev/null
  fi

  echo "Updated $label: $actual_bundle_id"
}

echo "Simulator: $SIMULATOR_ID"
echo "Source:    $ROOT"

build_install_channel "SAVI Test" "Debug" "$DEBUG_DERIVED_DATA" "$DEBUG_BUNDLE_ID"
build_install_channel "SAVI main" "Release" "$RELEASE_DERIVED_DATA" "$RELEASE_BUNDLE_ID"

echo
echo "Updated both SAVI and SAVI Test"
echo "  SAVI Test: $DEBUG_BUNDLE_ID"
echo "  SAVI main: $RELEASE_BUNDLE_ID"
