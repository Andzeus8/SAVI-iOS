# SAVI Master Roadmap

This is the living execution map for SAVI. It connects product direction,
Apple compliance, backend/social work, analytics, desktop, and future Android.
When SAVI's architecture changes, update this file or add an ADR.

## Current Release Posture

SAVI's current TestFlight posture is private-save-first:

- native iOS app,
- share extension,
- local library,
- sample library,
- folders/Keepers,
- Search,
- personal Explore,
- Private Vault,
- local archive export/import,
- social hidden in Release/TestFlight.

Current Release/TestFlight must not expose:

- friend feeds,
- public profiles,
- public publishing controls,
- live Supabase writes,
- live PostHog analytics,
- admin dashboards,
- Founder Hub metrics.

## Roadmap Tracks

| Track | Goal | Status | Release Gate |
|---|---|---:|---|
| Private Save Core | Fast local save/search/organize | Active | TestFlight/App Store safe |
| Share Extension | Save from anywhere with smart folder/tags | Active | Real-device QA |
| Apple Compliance | Privacy, review, export, required APIs | In progress | Required before App Store |
| Analytics | Manual allowlisted events and founder dashboards | Planned/foundation | Privacy labels + opt-in/copy |
| Social V1 | Public web links, profiles, follows, hearts | Planned/foundation | Report/block/moderation/delete |
| Notifications | Social/account notifications | Not started | Accounts + APNs backend + privacy-safe copy |
| Admin Backend | Moderation and protected founder data | Not started | Required before public social |
| Mac Founder Hub | Internal dashboard/control room | Internal prototype | Never ship in consumer app |
| User Mac Companion | Browse/search/sync personal library | Prototype direction | Needs account/sync plan |
| Android | Native Android client | Future | Stable API contract |

## Backend Milestones

1. Create Supabase `dev` and `prod` projects.
2. Enable Sign in with Apple for accounts.
3. Run and test Social V1 schema/RLS in dev.
4. Add client-safe config only: Supabase URL + anon key.
5. Add PostHog `dev` and `prod` projects with manual capture only.
6. Build protected admin backend before moderation/live Founder Hub.
7. Add OpenAPI/JSON Schema before Android work begins.
8. Add APNs/device-token storage only after account auth and notification copy
   are designed.
9. Validate push readiness with `Docs/Backend/NotificationRunbook.md` before
   enabling notification permission prompts.

## Compliance Milestones

1. Finalize privacy policy URL and in-app privacy link.
2. Complete App Store privacy labels for the exact submitted build using
   `Docs/Architecture/PrivacyDataInventory.md`.
3. Verify privacy manifest and required-reason APIs with
   `Docs/Architecture/PrivacyManifestAudit.md`.
4. Verify third-party SDK/package inventory with
   `Docs/Architecture/ThirdPartySDKInventory.md`.
5. Confirm export compliance answer.
6. Add account deletion before accounts go live.
7. Add report/block/filter/moderation/delete before social goes live.
8. Prepare Apple Review notes and test account for any account/social build.

## Governance Rule

- `Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md` is the live cross-chat work tracker.
- `Docs/ChangeLog/YYYY-MM-DD.md` records meaningful app/build/doc changes.
- `Docs/Architecture/CTOHandoffIndex.md` is the first CTO/new-engineer read.
- ADRs capture decisions that affect stack, privacy, sync, social, analytics,
  desktop, Android, or App Store posture.
- `scripts/savi-safety-scan.sh` is the local guardrail for secrets and
  founder/admin separation.
