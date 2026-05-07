#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/SAVI.xcodeproj"
SCHEME="SAVI"
DERIVED_DATA="$ROOT/.DerivedData-fast-debug"
BUNDLE_ID="com.altatecrd.savi.personaldebug"
DEFAULT_SIM_NAME="${SAVI_FAST_SIM_NAME:-iPhone 17}"
SIMULATOR_ID="${SIMULATOR_ID:-}"
LAUNCH_APP=1
REINSTALL=0

usage() {
  cat <<'EOF'
Usage: scripts/savi-fast-dev-sim.sh [--simulator-id UDID] [--simulator-name NAME] [--reinstall] [--no-launch]

Fast SAVI dev loop:
  - Builds Debug only.
  - Installs only SAVI Test / com.altatecrd.savi.personaldebug.
  - Uses one simulator, defaulting to iPhone 17.
  - Does not build Release, update all simulators, archive, upload, or touch TestFlight.

Options:
  --simulator-id UDID    Use a specific simulator.
  --simulator-name NAME  Use/boot a simulator by name. Default: iPhone 17.
  --reinstall           Uninstall SAVI Test first. Useful when share extension state feels cached.
  --no-launch           Install without launching.

Environment:
  SIMULATOR_ID          Optional simulator UDID override.
  SAVI_FAST_SIM_NAME    Optional simulator name override.
  SAVI_XCODEBUILD_VERBOSE=1  Show full xcodebuild output.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --simulator-id)
      SIMULATOR_ID="${2:-}"
      shift 2
      ;;
    --simulator-name)
      DEFAULT_SIM_NAME="${2:-}"
      shift 2
      ;;
    --reinstall)
      REINSTALL=1
      shift
      ;;
    --no-launch)
      LAUNCH_APP=0
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

resolve_simulator_id() {
  if [[ -n "$SIMULATOR_ID" ]]; then
    echo "$SIMULATOR_ID"
    return 0
  fi

  local named_booted
  named_booted="$(xcrun simctl list devices booted | awk -v name="$DEFAULT_SIM_NAME" -F'[()]' '$0 ~ name && /Booted/ { print $2; exit }')"
  if [[ -n "$named_booted" ]]; then
    echo "$named_booted"
    return 0
  fi

  local first_booted
  first_booted="$(xcrun simctl list devices booted | awk -F'[()]' '/Booted/ { print $2; exit }')"
  if [[ -n "$first_booted" ]]; then
    echo "$first_booted"
    return 0
  fi

  local named_available
  named_available="$(xcrun simctl list devices available | awk -v name="$DEFAULT_SIM_NAME" -F'[()]' '$0 ~ name { print $2; exit }')"
  if [[ -z "$named_available" ]]; then
    echo "No booted simulator found, and no available simulator named '$DEFAULT_SIM_NAME'." >&2
    echo "Boot a simulator or pass --simulator-id." >&2
    exit 1
  fi

  echo "==> Booting $DEFAULT_SIM_NAME ($named_available)" >&2
  xcrun simctl boot "$named_available" 2>/dev/null || true
  echo "$named_available"
}

app_path() {
  find "$DERIVED_DATA/Build/Products/Debug-iphonesimulator" -maxdepth 1 -name "*.app" -print -quit
}

bundle_id_for_app() {
  local app="$1"
  /usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$app/Info.plist"
}

report_installed() {
  local app
  if ! app="$(xcrun simctl get_app_container "$SIMULATOR_ID" "$BUNDLE_ID" app 2>/dev/null)"; then
    echo "$BUNDLE_ID -> not installed"
    return 0
  fi

  local info="$app/Info.plist"
  local name version build
  name="$(/usr/libexec/PlistBuddy -c 'Print CFBundleDisplayName' "$info" 2>/dev/null || /usr/libexec/PlistBuddy -c 'Print CFBundleName' "$info")"
  version="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$info")"
  build="$(/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' "$info")"
  echo "$BUNDLE_ID -> app=$name version=$version build=$build"

  local appex
  for appex in "$app"/PlugIns/*.appex; do
    [[ -d "$appex" ]] || continue
    local appex_info="$appex/Info.plist"
    local appex_id appex_name appex_build
    appex_id="$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$appex_info")"
    appex_name="$(/usr/libexec/PlistBuddy -c 'Print CFBundleDisplayName' "$appex_info" 2>/dev/null || /usr/libexec/PlistBuddy -c 'Print CFBundleName' "$appex_info")"
    appex_build="$(/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' "$appex_info")"
    echo "  extension $appex_id -> $appex_name build=$appex_build"
  done
}

SIMULATOR_ID="$(resolve_simulator_id)"

quiet_args=()
if [[ "${SAVI_XCODEBUILD_VERBOSE:-0}" != "1" ]]; then
  quiet_args=(-quiet)
fi

echo "Simulator: $SIMULATOR_ID"
echo "Source:    $ROOT"
echo "Channel:   SAVI Test ($BUNDLE_ID)"

if [[ "$REINSTALL" -eq 1 ]] && xcrun simctl get_app_container "$SIMULATOR_ID" "$BUNDLE_ID" app >/dev/null 2>&1; then
  echo "==> Uninstalling SAVI Test"
  xcrun simctl uninstall "$SIMULATOR_ID" "$BUNDLE_ID" >/dev/null
fi

echo "==> Building SAVI Test (Debug)"
xcodebuild \
  "${quiet_args[@]}" \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -derivedDataPath "$DERIVED_DATA" \
  ONLY_ACTIVE_ARCH=YES \
  COMPILER_INDEX_STORE_ENABLE=NO \
  build

app="$(app_path)"
if [[ -z "$app" || ! -d "$app" ]]; then
  echo "Could not find built Debug app in $DERIVED_DATA" >&2
  exit 1
fi

actual_bundle_id="$(bundle_id_for_app "$app")"
if [[ "$actual_bundle_id" != "$BUNDLE_ID" ]]; then
  echo "Bundle ID mismatch:" >&2
  echo "  expected: $BUNDLE_ID" >&2
  echo "  actual:   $actual_bundle_id" >&2
  echo "  app:      $app" >&2
  exit 1
fi

echo "==> Installing SAVI Test"
xcrun simctl install "$SIMULATOR_ID" "$app"

if [[ "$LAUNCH_APP" -eq 1 ]]; then
  echo "==> Launching SAVI Test"
  xcrun simctl launch "$SIMULATOR_ID" "$BUNDLE_ID" >/dev/null
fi

echo
echo "Installed version:"
report_installed
