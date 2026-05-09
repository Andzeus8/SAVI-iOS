# SAVI Social Safety And App Store Checklist

Release/TestFlight must keep real social disabled until these requirements are complete.

## Social V1 Allowed Scope

- profiles,
- username search,
- follow/friend by username,
- public web link cards only,
- friends feed,
- one heart reaction,
- save a friend's public link,
- report profile/link,
- block user.

## Explicitly Excluded

- DMs,
- comments,
- contacts upload,
- public PDFs,
- public screenshots,
- private files,
- private vault content,
- local private documents.

## Required Before External Social Launch

- backend reports table and moderation workflow,
- backend blocks table and feed exclusion,
- protected admin moderation queue,
- moderation audit log,
- ability to unpublish/delete own public links,
- account deletion path,
- privacy policy update,
- App Store privacy label update,
- App Review notes explaining UGC controls,
- test account instructions for Apple review,
- RLS enabled and tested on every social table.

## App-Side Gates

- `SaviReleaseGate.socialFeaturesEnabled` must stay `false` in Release until the checklist is complete.
- Release should show only the small “Friends are coming” teaser.
- Debug/SAVI Test can use the mock social backend and later Supabase staging.

## Backend References

- `Docs/Backend/AdminModerationWorkflow.md`
- `Docs/Backend/OpenAPI/savi-admin-v1.openapi.yaml`
- `Docs/Backend/OpenAPI/savi-social-v1.openapi.yaml`
- `Docs/Backend/Supabase/social_v1_schema.sql`
- `Docs/Backend/Supabase/rls_test_plan.sql`
