#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

RUN_IOS_RELEASE_BUILD=0
RUN_MAC_DEBUG_BUILD=0
RUN_MAC_RELEASE_BUILD=0

usage() {
  cat <<'USAGE'
SAVI preflight

Usage:
  scripts/savi-preflight.sh [--quick] [--release-build] [--mac-debug-build] [--mac-release-build] [--all-builds]

Default / --quick:
  - git diff --check
  - scripts/savi-safety-scan.sh
  - scripts/savi-backend-readiness-check.py
  - scripts/savi-supabase-rls-check.py
  - scripts/savi-openapi-contract-check.py
  - scripts/savi-account-deletion-check.py
  - scripts/savi-moderation-readiness-check.py
  - scripts/savi-notification-readiness-check.py
  - scripts/savi-contract-fixtures-check.py
  - scripts/savi-analytics-contract-check.py
  - scripts/savi-privacy-inventory-check.py
  - scripts/savi-appstore-privacy-labels-check.py
  - scripts/savi-appstore-export-compliance-check.py
  - scripts/savi-privacy-manifest-check.py
  - scripts/savi-sdk-inventory-check.py
  - scripts/savi-sample-content-check.py
  - scripts/savi-public-site-check.py
  - scripts/savi-appstore-metadata-check.py
  - scripts/savi-appstore-age-rating-check.py
  - scripts/savi-testflight-ops-check.py
  - scripts/savi-crash-performance-check.py
  - scripts/savi-share-extension-qa-check.py
  - scripts/savi-archive-restore-check.py
  - scripts/savi-appstore-readiness-check.py
  - scripts/savi-docs-link-check.py
  - public-site TODO reminder

Build flags:
  --release-build      Run iOS Release generic iPhoneOS no-sign build.
  --mac-debug-build    Run SAVI Mac Debug build.
  --mac-release-build  Run SAVI Mac Release build.
  --all-builds         Run all build checks above.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --quick)
      ;;
    --release-build)
      RUN_IOS_RELEASE_BUILD=1
      ;;
    --mac-debug-build)
      RUN_MAC_DEBUG_BUILD=1
      ;;
    --mac-release-build)
      RUN_MAC_RELEASE_BUILD=1
      ;;
    --all-builds)
      RUN_IOS_RELEASE_BUILD=1
      RUN_MAC_DEBUG_BUILD=1
      RUN_MAC_RELEASE_BUILD=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 2
      ;;
  esac
  shift
done

step() {
  printf '\n== %s ==\n' "$1"
}

step "Git whitespace check"
git diff --check

step "SAVI safety scan"
scripts/savi-safety-scan.sh

step "Backend/social readiness"
scripts/savi-backend-readiness-check.py

step "Supabase RLS"
scripts/savi-supabase-rls-check.py

step "OpenAPI contract"
scripts/savi-openapi-contract-check.py

step "Account deletion readiness"
scripts/savi-account-deletion-check.py

step "Moderation readiness"
scripts/savi-moderation-readiness-check.py

step "Notification readiness"
scripts/savi-notification-readiness-check.py

step "Contract fixtures"
scripts/savi-contract-fixtures-check.py

step "Analytics contract"
scripts/savi-analytics-contract-check.py

step "Privacy data inventory"
scripts/savi-privacy-inventory-check.py

step "App Store privacy labels"
scripts/savi-appstore-privacy-labels-check.py

step "App Store export compliance"
scripts/savi-appstore-export-compliance-check.py

step "Privacy manifest"
scripts/savi-privacy-manifest-check.py

step "Third-party SDK inventory"
scripts/savi-sdk-inventory-check.py

step "Sample content safety"
scripts/savi-sample-content-check.py

step "Public site static packet"
scripts/savi-public-site-check.py

step "App Store metadata"
scripts/savi-appstore-metadata-check.py

step "App Store age rating"
scripts/savi-appstore-age-rating-check.py

step "TestFlight operations"
scripts/savi-testflight-ops-check.py

step "Crash and performance triage"
scripts/savi-crash-performance-check.py

step "Share extension real-device QA"
scripts/savi-share-extension-qa-check.py

step "Archive export/restore QA"
scripts/savi-archive-restore-check.py

step "App Store readiness"
scripts/savi-appstore-readiness-check.py

step "Docs link integrity"
scripts/savi-docs-link-check.py

step "Public-site placeholder reminder"
if rg -n "TODO" Docs/PublicSite >/tmp/savi_public_site_todos.txt 2>/dev/null; then
  echo "WARN: public-site templates still contain TODO placeholders."
  echo "      This is OK before domain/legal setup, but must be resolved before App Store submission."
  sed -n '1,40p' /tmp/savi_public_site_todos.txt
else
  echo "OK: no TODO placeholders in Docs/PublicSite"
fi

if [[ "$RUN_IOS_RELEASE_BUILD" -eq 1 ]]; then
  step "iOS Release generic iPhoneOS no-sign build"
  xcodebuild \
    -project SAVI.xcodeproj \
    -scheme SAVI \
    -configuration Release \
    -sdk iphoneos \
    -destination 'generic/platform=iOS' \
    CODE_SIGNING_ALLOWED=NO \
    build
fi

if [[ "$RUN_MAC_DEBUG_BUILD" -eq 1 ]]; then
  step "SAVI Mac Debug build"
  xcodebuild \
    -project SAVI.xcodeproj \
    -scheme "SAVI Mac" \
    -configuration Debug \
    -destination 'platform=macOS' \
    CODE_SIGNING_ALLOWED=NO \
    build
fi

if [[ "$RUN_MAC_RELEASE_BUILD" -eq 1 ]]; then
  step "SAVI Mac Release build"
  xcodebuild \
    -project SAVI.xcodeproj \
    -scheme "SAVI Mac" \
    -configuration Release \
    -destination 'platform=macOS' \
    CODE_SIGNING_ALLOWED=NO \
    build
fi

step "Preflight complete"
echo "SAVI preflight passed"
