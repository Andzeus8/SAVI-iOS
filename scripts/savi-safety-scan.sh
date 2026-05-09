#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "== SAVI safety scan =="

fail=0

echo "-- Checking iOS targets for founder/admin dashboard strings"
if rg -n "Founder Hub|SaviFounder|PostHog Query|Mock active testers|Rabbit Hole Radar|Codex Workshop" SAVI SAVIShareExtension Shared --glob '!**/*.xcprivacy' >/tmp/savi_founder_scan.txt 2>/dev/null; then
  cat /tmp/savi_founder_scan.txt
  fail=1
else
  echo "OK: no founder/admin dashboard strings in consumer/shared iOS paths"
fi

echo "-- Checking for likely committed secrets"
if rg -n "(SUPABASE_SERVICE_ROLE|POSTHOG_PERSONAL|POSTHOG_QUERY|DATABASE_URL=|DB_PASSWORD|PRIVATE_KEY=|BEGIN PRIVATE KEY|sk_live_|ghp_[A-Za-z0-9_]{20,})" . \
  --glob '!build/**' \
  --glob '!.git/**' \
  --glob '!scripts/savi-safety-scan.sh' \
  --glob '!*.xcuserstate' \
  --glob '!Docs/**' >/tmp/savi_secret_scan.txt 2>/dev/null; then
  cat /tmp/savi_secret_scan.txt
  fail=1
else
  echo "OK: no likely app/admin secrets found outside docs/build/git"
fi

echo "-- Checking documentation front doors"
for file in \
  Docs/Architecture/CTOHandoffIndex.md \
  Docs/Architecture/MasterRoadmap.md \
  Docs/Architecture/AppStoreComplianceMatrix.md \
  Docs/Architecture/PrivacyDataInventory.md \
  Docs/Architecture/Runbooks/AppStorePrivacyLabels.md \
  Docs/Architecture/PrivacyManifestAudit.md \
  Docs/Architecture/ThirdPartySDKInventory.md \
  Docs/Architecture/SampleContentReview.md \
  Docs/Architecture/SocialV1ImplementationPlan.md \
  Docs/Architecture/SocialMobileUXAndNotifications.md \
  Docs/Architecture/DesktopAndFounderHubRoadmap.md \
  Docs/Architecture/Runbooks/AppStoreSubmissionPacket.md \
  Docs/Architecture/Runbooks/AppStoreConnectMetadata.md \
  Docs/Architecture/Runbooks/AppStoreAgeRating.md \
  Docs/Architecture/Runbooks/AppStoreExportCompliance.md \
  Docs/Architecture/Runbooks/TestFlightOperations.md \
  Docs/Architecture/Runbooks/CrashAndPerformanceTriage.md \
  Docs/Architecture/Runbooks/ShareExtensionRealDeviceQA.md \
  Docs/Architecture/Runbooks/ArchiveExportRestoreQA.md \
  Docs/Architecture/Runbooks/StatusReports.md \
  Docs/Backend/AccountDeletionRunbook.md \
  Docs/Backend/AdminModerationWorkflow.md \
  Docs/Backend/NotificationRunbook.md \
  Docs/Backend/OpenAPI/savi-social-v1.openapi.yaml \
  Docs/Backend/OpenAPI/savi-admin-v1.openapi.yaml \
  Docs/Backend/Schemas/analytics-event.schema.json \
  Docs/Backend/Schemas/public-link.schema.json \
  Docs/Backend/Schemas/savi-item.schema.json \
  Docs/Backend/Fixtures/README.md \
  Docs/Backend/Fixtures/valid/public-link-video.json \
  Docs/Backend/Fixtures/invalid/public-link-private-file.json \
  Docs/Backend/Supabase/rls_test_plan.sql \
  Docs/Backend/PostHog/dashboard-specs.json \
  Docs/PublicSite/privacy.md \
  Docs/PublicSite/support.md \
  Docs/PublicSite/data-deletion.md
do
  if [[ ! -f "$file" ]]; then
    echo "Missing: $file"
    fail=1
  fi
done

if [[ "$fail" -ne 0 ]]; then
  echo "SAVI safety scan failed"
  exit 1
fi

echo "SAVI safety scan passed"
