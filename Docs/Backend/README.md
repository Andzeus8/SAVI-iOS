# SAVI Backend Direction

This folder documents the incremental path from local-only SAVI to real backend-supported social, analytics, sync, and future macOS companion work.

For the full senior architecture map, start with:

- `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/README.md`
- `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/PrivacyDataInventory.md`

## Decisions

- Supabase is the future social backend.
- PostHog is the future product analytics and founder dashboard layer.
- CloudKit is not the social network or analytics system.
- CloudKit remains optional private Apple backup/sync later.
- Release/TestFlight keeps social hidden until moderation, privacy, account deletion, and App Store review requirements are complete.

## Files

- `AnalyticsEventCatalog.md` - privacy-safe event allowlist.
- `PostHogDashboardPlan.md` - founder/investor dashboard plan.
- `AccountDeletionRunbook.md` - account deletion and Sign in with Apple revocation path.
- `NotificationRunbook.md` - future APNs/device-token/settings privacy contract.
- `SocialSafetyChecklist.md` - App Store and UGC safety gate.
- `AdminModerationWorkflow.md` - protected admin moderation workflow.
- `SAVIBackendConfig.template.xcconfig` - safe public config placeholders.
- `MacCompanionArchitecture.md` - macOS companion direction.
- `Supabase/social_v1_schema.sql` - Supabase Social V1 schema and RLS draft.
- `Supabase/rls_test_plan.sql` - credential-free RLS test plan.
- `OpenAPI/savi-social-v1.openapi.yaml` - portable Social V1 API contract.
- `OpenAPI/savi-admin-v1.openapi.yaml` - internal admin moderation API draft.
- `Schemas/` - JSON schemas for item, public link, and analytics event.
- `Fixtures/` - valid/invalid payload examples for app, backend, Android, and analytics contracts.
- `PostHog/dashboard-specs.json` - dashboard/event grouping spec.

## Setup Needed Later

After the accounts exist, provide only:

- Supabase Project URL,
- Supabase anon public key,
- PostHog host,
- PostHog project token.

Never put Supabase service-role keys or admin secrets in the iOS or macOS app.
