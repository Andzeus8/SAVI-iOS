#!/usr/bin/env bash
set -euo pipefail

PROJECT="${PROJECT:-/Users/guest1/Documents/SAVI-iOS/SAVI.xcodeproj}"
SCHEME="${SCHEME:-SAVI}"
CONFIGURATION="${CONFIGURATION:-Debug}"
REPO_ROOT="${REPO_ROOT:-/Users/guest1/Documents/SAVI-iOS}"
OUTPUT_ROOT="${OUTPUT_ROOT:-$REPO_ROOT/build/production-ui-qa}"
DERIVED_DATA="${DERIVED_DATA:-$OUTPUT_ROOT/DerivedData}"
RUNTIME="${RUNTIME:-com.apple.CoreSimulator.SimRuntime.iOS-26-4}"
LAUNCH_WAIT_SECONDS="${LAUNCH_WAIT_SECONDS:-4}"
FIRST_LAUNCH_WAIT_SECONDS="${FIRST_LAUNCH_WAIT_SECONDS:-8}"
LAUNCH_TIMEOUT_SECONDS="${LAUNCH_TIMEOUT_SECONDS:-60}"
SIMCTL_TIMEOUT_SECONDS="${SIMCTL_TIMEOUT_SECONDS:-45}"
BOOT_SETTLE_SECONDS="${BOOT_SETTLE_SECONDS:-6}"
SHUTDOWN_AFTER_DEVICE="${SHUTDOWN_AFTER_DEVICE:-1}"
BYPASS_ONBOARDING="${BYPASS_ONBOARDING:-1}"
SKIP_BUILD="${SKIP_BUILD:-0}"

STAMP="$(date +%Y%m%d-%H%M%S)"
RUN_DIR="$OUTPUT_ROOT/$STAMP"
mkdir -p "$RUN_DIR"

read_bundle_id() {
  xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination 'generic/platform=iOS Simulator' \
    -showBuildSettings 2>/dev/null |
    awk -F'= ' '/PRODUCT_BUNDLE_IDENTIFIER/ {print $2; exit}'
}

BUNDLE_ID="${BUNDLE_ID:-$(read_bundle_id)}"
if [[ -z "${BUNDLE_ID:-}" ]]; then
  echo "Could not determine bundle id. Set BUNDLE_ID and rerun." >&2
  exit 1
fi

DEVICE_MATRIX_DEFAULT=$'SAVI QA iPhone SE|com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation\nSAVI QA iPhone 17|com.apple.CoreSimulator.SimDeviceType.iPhone-17\nSAVI QA iPhone 17 Pro Max|com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max\nSAVI QA iPhone Air|com.apple.CoreSimulator.SimDeviceType.iPhone-Air'
DEVICE_MATRIX="${DEVICE_MATRIX:-$DEVICE_MATRIX_DEFAULT}"
TABS="${TABS:-home search explore folders profile}"
APPEARANCES="${APPEARANCES:-light dark}"

device_udid_for_name() {
  local name="$1"
  xcrun simctl list devices available |
    grep -F "    $name (" |
    head -1 |
    sed -E 's/.*\(([A-Fa-f0-9-]+)\).*/\1/'
}

ensure_device() {
  local name="$1"
  local type_id="$2"
  local udid
  udid="$(device_udid_for_name "$name" || true)"
  if [[ -n "$udid" && "$udid" != "$name" ]]; then
    printf '%s\n' "$udid"
    return
  fi

  echo "Creating simulator: $name" >&2
  xcrun simctl create "$name" "$type_id" "$RUNTIME"
}

build_app() {
  if [[ "$SKIP_BUILD" == "1" ]]; then
    return
  fi

  xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$DERIVED_DATA" \
    build
}

app_path() {
  printf '%s/Build/Products/%s-iphonesimulator/%s.app\n' "$DERIVED_DATA" "$CONFIGURATION" "$SCHEME"
}

run_with_timeout() {
  local label="$1"
  local seconds="$2"
  shift 2

  local pid
  local elapsed_tenths=0
  local timeout_tenths=$((seconds * 10))

  "$@" &
  pid=$!
  while kill -0 "$pid" >/dev/null 2>&1; do
    if (( elapsed_tenths >= timeout_tenths )); then
      kill "$pid" >/dev/null 2>&1 || true
      wait "$pid" >/dev/null 2>&1 || true
      echo "$label timed out after ${seconds}s" >&2
      return 124
    fi
    sleep 0.1
    elapsed_tenths=$((elapsed_tenths + 1))
  done

  wait "$pid"
}

shutdown_device_if_needed() {
  local udid="$1"
  local device_name="$2"

  if [[ "$SHUTDOWN_AFTER_DEVICE" != "1" ]]; then
    return
  fi

  run_with_timeout "Shutdown $device_name" "$SIMCTL_TIMEOUT_SECONDS" \
    xcrun simctl shutdown "$udid" >/dev/null 2>&1 || true
}

launch_tab() {
  local udid="$1"
  local tab="$2"
  local pid
  local elapsed_tenths=0
  local timeout_tenths=$((LAUNCH_TIMEOUT_SECONDS * 10))

  run_with_timeout "Terminate on $udid" "$SIMCTL_TIMEOUT_SECONDS" \
    xcrun simctl terminate "$udid" "$BUNDLE_ID" >/dev/null 2>&1 || true
  if [[ "$tab" == "home" ]]; then
    SIMCTL_CHILD_SAVI_QA_BYPASS_ONBOARDING="$BYPASS_ONBOARDING" \
      xcrun simctl launch --terminate-running-process "$udid" "$BUNDLE_ID" >/dev/null &
  else
    SIMCTL_CHILD_SAVI_QA_BYPASS_ONBOARDING="$BYPASS_ONBOARDING" \
    SIMCTL_CHILD_SAVI_START_TAB="$tab" \
      xcrun simctl launch --terminate-running-process "$udid" "$BUNDLE_ID" >/dev/null &
  fi
  pid=$!

  while kill -0 "$pid" >/dev/null 2>&1; do
    if (( elapsed_tenths >= timeout_tenths )); then
      kill "$pid" >/dev/null 2>&1 || true
      wait "$pid" >/dev/null 2>&1 || true
      echo "Launch timed out for $BUNDLE_ID on $udid ($tab)" >&2
      return 124
    fi
    sleep 0.1
    elapsed_tenths=$((elapsed_tenths + 1))
  done

  wait "$pid"
  sleep "$LAUNCH_WAIT_SECONDS"
}

safe_name() {
  printf '%s' "$1" |
    tr '[:upper:]' '[:lower:]' |
    sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

build_app

APP_PATH="$(app_path)"
if [[ ! -d "$APP_PATH" ]]; then
  echo "Built app not found at $APP_PATH" >&2
  exit 1
fi

SUMMARY="$RUN_DIR/summary.txt"
FAILURES=0
{
  echo "SAVI production UI QA"
  echo "Run: $STAMP"
  echo "Bundle: $BUNDLE_ID"
  echo "Tabs: $TABS"
  echo "Appearances: $APPEARANCES"
  echo "Bypass onboarding: $BYPASS_ONBOARDING"
  echo
} > "$SUMMARY"

while IFS='|' read -r device_name device_type; do
  [[ -z "${device_name:-}" || -z "${device_type:-}" ]] && continue

  UDID="$(ensure_device "$device_name" "$device_type")"
  echo "Booting $device_name ($UDID)"
  xcrun simctl boot "$UDID" >/dev/null 2>&1 || true
  run_with_timeout "Boot status on $device_name" "$SIMCTL_TIMEOUT_SECONDS" \
    xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1 || true
  sleep "$BOOT_SETTLE_SECONDS"
  run_with_timeout "Uninstall on $device_name" "$SIMCTL_TIMEOUT_SECONDS" \
    xcrun simctl uninstall "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
  if ! run_with_timeout "Install on $device_name" "$SIMCTL_TIMEOUT_SECONDS" \
    xcrun simctl install "$UDID" "$APP_PATH"; then
    echo "$device_name | install failed" | tee -a "$SUMMARY"
    FAILURES=$((FAILURES + 1))
    shutdown_device_if_needed "$UDID" "$device_name"
    continue
  fi

  device_slug="$(safe_name "$device_name")"
  did_launch_device=0
  for appearance in $APPEARANCES; do
    xcrun simctl ui "$UDID" appearance "$appearance" >/dev/null

    for tab in $TABS; do
      if ! launch_tab "$UDID" "$tab"; then
        echo "$device_name | $appearance | $tab | launch failed" | tee -a "$SUMMARY"
        FAILURES=$((FAILURES + 1))
        continue
      fi
      if [[ "$did_launch_device" == "0" ]]; then
        sleep "$FIRST_LAUNCH_WAIT_SECONDS"
        did_launch_device=1
      fi
      screenshot="$RUN_DIR/${device_slug}-${appearance}-${tab}.png"
      xcrun simctl io "$UDID" screenshot "$screenshot" >/dev/null
      echo "$device_name | $appearance | $tab | $screenshot" | tee -a "$SUMMARY"
    done
  done

  shutdown_device_if_needed "$UDID" "$device_name"
done <<< "$DEVICE_MATRIX"

echo
echo "QA screenshots written to: $RUN_DIR"
echo "Summary: $SUMMARY"

if (( FAILURES > 0 )); then
  echo "QA completed with $FAILURES failure(s)." >&2
  exit 1
fi
