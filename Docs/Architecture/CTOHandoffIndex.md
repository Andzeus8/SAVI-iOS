# SAVI CTO Handoff Index

This is the first file a future CTO, senior engineer, or new Codex chat should
read.

## Read First

1. `AGENTS.md`
2. `Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
3. `Docs/Architecture/MasterRoadmap.md`
4. `Docs/Architecture/README.md`
5. `Docs/ProductionReadiness.md`
6. `Docs/Architecture/Runbooks/AppStoreSubmissionPacket.md`
7. `Docs/TestFlightReadiness.md`

## Current Product Truth

- Active repo: `/Users/guest1/Documents/SAVI-iOS`
- Main app target: `SAVI`
- Share extension target: `SAVIShareExtension`
- Internal Mac target: `SAVI Mac`
- Release bundle: `com.altatecrd.savi`
- Debug/internal bundle: `com.altatecrd.savi.personaldebug`
- Current TestFlight posture: private-save-first, social hidden.

## Stack Decisions

- iOS remains native SwiftUI.
- Android later should be native Kotlin/Compose against shared backend contracts.
- Supabase is future accounts/social/public-link sync.
- PostHog is future product analytics/founder dashboards.
- CloudKit is optional Apple-private backup later only.
- Founder Hub/admin stays out of consumer app.

## Must-Read Architecture Docs

- `SystemContext.md`
- `ClientArchitecture.md`
- `BackendArchitecture.md`
- `DataModel.md`
- `APIContract.md`
- `AnalyticsEvents.md`
- `PrivacyDataInventory.md`
- `PrivacyManifestAudit.md`
- `ThirdPartySDKInventory.md`
- `SampleContentReview.md`
- `SecurityAndPrivacy.md`
- `AndroidReadiness.md`
- `AppStoreComplianceMatrix.md`
- `SocialV1ImplementationPlan.md`
- `SocialMobileUXAndNotifications.md`
- `DesktopAndFounderHubRoadmap.md`
- `MockFlows/MockSocialAndAdminFlows.md`

## Must-Read Backend Docs

- `Docs/Backend/README.md`
- `Docs/Backend/AnalyticsEventCatalog.md`
- `Docs/Backend/PostHogDashboardPlan.md`
- `Docs/Backend/AccountDeletionRunbook.md`
- `Docs/Backend/NotificationRunbook.md`
- `Docs/Backend/SocialSafetyChecklist.md`
- `Docs/Backend/AdminModerationWorkflow.md`
- `Docs/Backend/Supabase/social_v1_schema.sql`
- `Docs/Backend/SAVIBackendConfig.template.xcconfig`
- `Docs/Backend/OpenAPI/savi-social-v1.openapi.yaml`
- `Docs/Backend/OpenAPI/savi-admin-v1.openapi.yaml`
- `Docs/Backend/Schemas/`
- `Docs/Backend/Fixtures/`
- `Docs/Backend/Supabase/rls_test_plan.sql`
- `Docs/Backend/PostHog/dashboard-specs.json`
- `Docs/PublicSite/`
- `Docs/Architecture/Runbooks/PreflightAutomation.md`
- `Docs/Architecture/Runbooks/GitHubActions.md`
- `Docs/Architecture/Runbooks/StatusReports.md`
- `Docs/Architecture/Runbooks/AppStoreConnectMetadata.md`
- `Docs/Architecture/Runbooks/AppStorePrivacyLabels.md`
- `Docs/Architecture/Runbooks/AppStoreAgeRating.md`
- `Docs/Architecture/Runbooks/AppStoreExportCompliance.md`
- `Docs/Architecture/Runbooks/TestFlightOperations.md`
- `Docs/Architecture/Runbooks/CrashAndPerformanceTriage.md`
- `Docs/Architecture/Runbooks/ShareExtensionRealDeviceQA.md`
- `Docs/Architecture/Runbooks/ArchiveExportRestoreQA.md`

## Decision Records

- `ADRs/0001-native-clients-shared-backend.md`
- `ADRs/0002-supabase-posthog-cloudkit-roles.md`
- `ADRs/0003-founder-hub-admin-separation.md`

## Operating Rules

- Update the active work log before/after meaningful work.
- Update daily changelog for app/build/docs milestones.
- Add an ADR for architecture, privacy, sync, social, backend, analytics,
  desktop, Android, or App Store direction changes.
- Never revert unrelated dirty files from another chat.
- Never ship admin secrets in app targets.
- Run `scripts/savi-safety-scan.sh` before social/backend/TestFlight-sensitive
  changes.
- Run `scripts/savi-backend-readiness-check.py` before connecting real
  Supabase/PostHog accounts or enabling social UI outside Debug.
- Run `scripts/savi-supabase-rls-check.py` when changing Supabase tables,
  policies, public-link eligibility, reports, blocks, follows, or likes.
- Run `scripts/savi-openapi-contract-check.py` when changing the Social V1 API,
  public-link eligibility, account deletion, report/block, or Android-facing
  backend contracts.
- Run `scripts/savi-account-deletion-check.py` when changing accounts, Sign in
  with Apple, deletion copy, Supabase cascades, or social launch readiness.
- Run `scripts/savi-moderation-readiness-check.py` when changing moderation,
  report status, public-link hide/unhide, admin APIs, or social App Store
  readiness docs.
- Run `scripts/savi-notification-readiness-check.py` when changing push,
  APNs, device-token storage, notification settings, or notification copy.
- Run `scripts/savi-contract-fixtures-check.py` when changing backend payload
  shape, Android contracts, public-link rules, or analytics events.
- Run `scripts/savi-analytics-contract-check.py` when changing analytics event
  names, property keys, fixtures, or PostHog-facing contracts.
- Run `scripts/savi-privacy-inventory-check.py` when changing privacy labels,
  data collection, SDKs, accounts, analytics, APNs, sync, or public social.
- Run `scripts/savi-appstore-privacy-labels-check.py` when changing App Store
  privacy-label answers, support/feedback collection, local-only collection
  assumptions, Supabase/PostHog/APNs/social status, or privacy submission docs.
- Run `scripts/savi-appstore-age-rating-check.py` when changing App Store age
  rating answers, sample content, health research framing, browser/unrestricted
  web behavior, Kids-category posture, or social/UGC release posture.
- Run `scripts/savi-appstore-export-compliance-check.py` when changing export
  compliance answers, Info.plist export keys, networking/security/encryption
  code, third-party SDKs, backend clients, custom archives, or distributed Mac
  app posture.
- Run `scripts/savi-privacy-manifest-check.py` when changing required-reason
  API use, privacy manifests, persistence APIs, SDKs, or app extensions.
- Run `scripts/savi-sdk-inventory-check.py` when adding/removing packages,
  third-party SDKs, frameworks, analytics/crash SDKs, or dependency managers.
- Run `scripts/savi-sample-content-check.py` when changing sample-library
  health hooks, meme/video links, fake private documents, rabbit-hole links,
  sample thumbnails, or sample-source documentation.
- Run `scripts/savi-appstore-metadata-check.py` when changing TestFlight copy,
  App Store Connect metadata, screenshots, review notes, build numbers, app
  naming, keywords, or App Store submission docs.
- Run `scripts/savi-testflight-ops-check.py` when changing TestFlight groups,
  internal tester emails, latest uploaded build numbers, tester instructions,
  or old-build troubleshooting docs.
- Run `scripts/savi-crash-performance-check.py` when changing crash triage,
  performance runbooks, iPhone 11/legacy-device notes, TestFlight feedback
  intake, scroll-jank handling, or privacy-safe diagnostics docs.
- Run `scripts/savi-share-extension-qa-check.py` when changing Share Sheet
  setup, share extension UI, share extraction, metadata fallback, app-group
  import, folder/tag suggestions from shared content, or real-device Share
  Extension QA docs.
- Run `scripts/savi-archive-restore-check.py` when changing Profile backup,
  full archive export, compact JSON backup, file importer/exporter behavior,
  restore previews, sample clearing/restoring, Private Vault restore behavior,
  or archive QA docs.
- Run `scripts/savi-appstore-readiness-check.py` before TestFlight/App Store
  submission-sensitive changes.
- Run `scripts/savi-status-report.py` when starting a new chat or verifying
  what is local versus uploaded to TestFlight.
- Run `scripts/savi-docs-link-check.py` when changing docs, handoffs,
  runbooks, or architecture references.
- Prefer `scripts/savi-preflight.sh` as the one-command local gate; use
  `scripts/savi-preflight.sh --all-builds` before major handoffs or releases.
- GitHub Actions has a credential-free preflight workflow at
  `.github/workflows/savi-preflight.yml`; it does not upload builds or use
  secrets.
