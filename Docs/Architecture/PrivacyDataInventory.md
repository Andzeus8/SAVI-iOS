# SAVI Privacy Data Inventory

This is the living source for App Store privacy-label preparation. Apple's App
Store privacy flow expects the developer to know what data the app and
third-party partners collect, why it is collected, and whether it is linked to
the user's identity.

This inventory is not legal advice. Re-audit the exact submitted build in App
Store Connect before every external release.

Source anchors:

- Apple app privacy details: https://developer.apple.com/app-store/app-privacy-details/
- App Store Connect app privacy reference: https://developer.apple.com/help/app-store-connect/reference/app-privacy/
- Manage app privacy: https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy
- Current answer packet: `Docs/Architecture/Runbooks/AppStorePrivacyLabels.md`

## Current Private-Save Release

Current Release/TestFlight posture:

- no required SAVI account,
- no live Supabase production collection,
- no live PostHog production analytics,
- no push notifications/device-token collection,
- no public social publishing,
- no public friend feed,
- local library stored on device,
- full archive export/import is user-controlled,
- feedback/TestFlight reports are user-initiated.

Draft privacy-label posture for the current private-save-first build:

| Area | Current Collection By SAVI | Linked To User | Notes |
|---|---|---:|---|
| Private saved links/notes/files/screenshots | No backend collection | No | Stored locally/on-device unless the user exports or shares feedback |
| Share extension saves | Local app/app-group storage | No | Same local-first library path |
| Private Vault content | No backend collection | No | Must remain out of analytics/social/sync |
| Feedback email/TestFlight feedback | User-initiated only | Possibly | Tester may choose to send email, screenshots, crash details, or text |
| Link metadata requests | App fetches previews from target sites/providers | Not SAVI collection unless proxied | Revisit if SAVI adds a metadata proxy |
| Crash/diagnostic data | Apple/TestFlight path if tester opts in | Apple/TestFlight behavior | Revisit before full App Store and third-party crash SDKs |
| Analytics | No live external analytics in current Release | No | PostHog remains disabled unless configured and disclosed |
| Notifications | No APNs/device-token collection | No | Future only |

If the exact submitted build still matches the current scope above, the current
answer packet recommends the `No Data Collected` path, with a conservative
support-disclosure alternative if founder/legal decides user-initiated feedback
email should be listed. See `Docs/Architecture/Runbooks/AppStorePrivacyLabels.md`.

## Future Feature Inventory

These rows must be re-reviewed before enabling the related feature.

| Feature | Data Category To Review | Purpose | Linked To User? | Notes |
|---|---|---|---:|---|
| Sign in with Apple | User ID, account profile, email if provided | App functionality | Yes | Required before accounts/social/sync |
| Supabase profiles | Username, display name, avatar/color, bio | App functionality / social | Yes | Public profile fields are user-controlled |
| Follows/friends | Follow graph | App functionality / social | Yes | No contacts upload in V1 |
| Public links | Public URLs, titles, domains, thumbnails, tags selected for public link | App functionality / social | Yes | Explicit public web-link publishing only |
| Likes/hearts | Public-link reaction | App functionality / social | Yes | No comments/DMs in V1 |
| Reports/blocks | Safety action records | App functionality / safety | Yes | Required before public social |
| Account deletion | Deletion request/status metadata | App functionality / legal support | Yes | See `Docs/Backend/AccountDeletionRunbook.md` |
| APNs notifications | Device token, notification settings, permission state | App functionality | Yes | See `Docs/Backend/NotificationRunbook.md` |
| PostHog analytics | Allowlisted product interaction, build, OS, device/performance tier | Analytics | Usually yes if account-enabled | No autocapture/session replay |
| Diagnostics/crashes | Crash/failure buckets, build, OS, device tier | App functionality / analytics | Possibly | Do not include private content |
| Optional iCloud backup | User-selected private backup/sync data | App functionality | Apple/private path | Revisit if enabled |
| Metadata proxy | URL/domain metadata requested through SAVI servers | App functionality | Possibly | Needs explicit privacy-label review before launch |

## Data We Must Not Collect

Do not send these to Supabase, PostHog, APNs payloads, moderation queues,
Founder Hub, public feeds, or analytics:

- private note bodies,
- private file names,
- PDF/file contents,
- screenshot contents or OCR text,
- Private Vault content,
- recovery codes,
- door codes,
- IDs, insurance cards, passport details, bank details,
- raw clipboard contents,
- raw search queries,
- contacts/address book,
- APNs tokens in analytics.

## App Store Privacy Label Drafting Rules

- Current local-only saves are not developer collection unless SAVI receives
  them through a backend, analytics SDK, support channel, or feedback flow.
- Future accounts will make profile/social records linked to identity.
- Future public publishing is explicit and should still be disclosed as
  user-linked social/app functionality data.
- Future analytics must stay manual and allowlisted. No autocapture and no
  session replay unless a separate privacy review approves it.
- Public domain/trending dashboards may use public-published domains/URLs only.
- Search metrics should use safe buckets, not raw query text.
- Notification payloads must be generic and privacy-safe on the lock screen.
- Any new third-party SDK requires a third-party data-practice review before
  submission.
- Use `Docs/Architecture/ThirdPartySDKInventory.md` before adding SDKs or
  package dependencies.

## Update Triggers

Update this inventory, `Docs/Architecture/AppStoreComplianceMatrix.md`, and the
App Store Connect answers when adding or changing:

- Supabase,
- PostHog,
- APNs/push notifications,
- CloudKit/iCloud backup,
- public publishing,
- friend feeds,
- metadata proxying,
- crash/diagnostic SDKs,
- customer support tooling,
- ads/marketing SDKs,
- in-app purchases/subscriptions,
- location,
- contacts,
- health integrations,
- Android or user-facing Mac sync.

## Submission Checklist

Before external TestFlight or App Store release that includes new data flows:

- run `scripts/savi-appstore-privacy-labels-check.py`,
- run `scripts/savi-privacy-inventory-check.py`,
- run `scripts/savi-preflight.sh`,
- compare current app behavior to this inventory,
- update the privacy policy,
- update App Store privacy labels,
- update App Review notes,
- confirm no private-content analytics or notification payloads exist.
