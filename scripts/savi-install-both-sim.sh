#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/SAVI.xcodeproj"
SCHEME="SAVI"
DEBUG_DERIVED_DATA="$ROOT/.DerivedData-sync-debug"
RELEASE_DERIVED_DATA="$ROOT/.DerivedData-sync-release"
DEBUG_BUNDLE_ID="com.altatecrd.savi.personaldebug"
RELEASE_BUNDLE_ID="com.altatecrd.savi"
OLD_BUNDLE_ID="com.savi.app"
APP_GROUP_ID="group.com.altatecrd.savi.shared"
LAUNCH_APPS=1
CLEAN_INSTALL=0
BACKUP_ROOT="${SAVI_SIM_BACKUP_ROOT:-/Users/guest1/Desktop/SAVI_QA/sim-install-backups}"
SIMULATOR_ID="${SIMULATOR_ID:-}"

usage() {
  cat <<'EOF'
Usage: scripts/savi-install-both-sim.sh [--simulator-id UDID] [--no-launch] [--clean]

Builds and installs both SAVI simulator channels from the same source tree:
  Debug   -> SAVI Test -> com.altatecrd.savi.personaldebug
  Release -> SAVI      -> com.altatecrd.savi

Environment:
  SIMULATOR_ID  Optional booted simulator UDID override.
  SAVI_SIM_BACKUP_ROOT  Optional backup root for --clean.
  SAVI_XCODEBUILD_VERBOSE=1  Show full xcodebuild output.

Safety:
  When multiple simulators are booted, --simulator-id is required so updates do
  not silently land on the wrong device.
  --clean backs up current SAVI simulator containers before uninstalling old
  app installs and reinstalling fresh.
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
    --clean)
      CLEAN_INSTALL=1
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
  booted_sims=("${(@f)$(xcrun simctl list devices booted | awk -F'[()]' '/Booted/{print $2}')}")
  if [[ "${#booted_sims[@]}" -gt 1 ]]; then
    echo "Multiple booted simulators found. Pass --simulator-id explicitly:" >&2
    xcrun simctl list devices booted >&2
    exit 2
  fi
  SIMULATOR_ID="${booted_sims[1]:-}"
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

safe_backup_container() {
  local label="$1"
  local bundle_id="$2"
  local container_kind="$3"
  local backup_dir="$4"

  local container_path
  if ! container_path="$(xcrun simctl get_app_container "$SIMULATOR_ID" "$bundle_id" "$container_kind" 2>/dev/null)"; then
    return 0
  fi
  [[ -d "$container_path" ]] || return 0

  local dest="$backup_dir/$label-$container_kind"
  echo "==> Backing up $label $container_kind"
  ditto "$container_path" "$dest"
}

uninstall_if_present() {
  local bundle_id="$1"
  if xcrun simctl get_app_container "$SIMULATOR_ID" "$bundle_id" app >/dev/null 2>&1; then
    echo "==> Uninstalling $bundle_id"
    xcrun simctl uninstall "$SIMULATOR_ID" "$bundle_id" >/dev/null
  fi
}

clean_existing_installs() {
  local timestamp
  timestamp="$(date +%Y%m%d-%H%M%S)"
  local backup_dir="$BACKUP_ROOT/$timestamp-$SIMULATOR_ID"
  mkdir -p "$backup_dir"

  safe_backup_container "SAVI-main" "$RELEASE_BUNDLE_ID" "data" "$backup_dir"
  safe_backup_container "SAVI-main" "$RELEASE_BUNDLE_ID" "$APP_GROUP_ID" "$backup_dir"
  safe_backup_container "SAVI-test" "$DEBUG_BUNDLE_ID" "data" "$backup_dir"
  safe_backup_container "SAVI-test" "$DEBUG_BUNDLE_ID" "$APP_GROUP_ID" "$backup_dir"
  safe_backup_container "SAVI-old" "$OLD_BUNDLE_ID" "data" "$backup_dir"

  uninstall_if_present "$RELEASE_BUNDLE_ID"
  uninstall_if_present "$DEBUG_BUNDLE_ID"
  uninstall_if_present "$OLD_BUNDLE_ID"

  echo "Backup: $backup_dir"
}

report_installed_channel() {
  local bundle_id="$1"
  local app
  if ! app="$(xcrun simctl get_app_container "$SIMULATOR_ID" "$bundle_id" app 2>/dev/null)"; then
    echo "$bundle_id -> not installed"
    return 0
  fi

  local info="$app/Info.plist"
  local name version build
  name="$(/usr/libexec/PlistBuddy -c 'Print CFBundleDisplayName' "$info" 2>/dev/null || /usr/libexec/PlistBuddy -c 'Print CFBundleName' "$info")"
  version="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$info")"
  build="$(/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' "$info")"
  echo "$bundle_id -> app=$name version=$version build=$build"

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

if [[ "$CLEAN_INSTALL" -eq 1 ]]; then
  clean_existing_installs
fi

build_install_channel "SAVI Test" "Debug" "$DEBUG_DERIVED_DATA" "$DEBUG_BUNDLE_ID"
build_install_channel "SAVI main" "Release" "$RELEASE_DERIVED_DATA" "$RELEASE_BUNDLE_ID"

echo
echo "Updated both SAVI and SAVI Test"
echo "  SAVI Test: $DEBUG_BUNDLE_ID"
echo "  SAVI main: $RELEASE_BUNDLE_ID"
echo
echo "Installed versions:"
report_installed_channel "$RELEASE_BUNDLE_ID"
report_installed_channel "$DEBUG_BUNDLE_ID"
report_installed_channel "$OLD_BUNDLE_ID"
