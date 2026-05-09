# SAVI App Store Privacy Labels

Use this before answering App Store Connect privacy questions for TestFlight,
external beta, or App Store submission. It translates SAVI's current
private-save-first build into a practical privacy-label packet.

This is not legal advice. The founder/legal owner must confirm the final
answers for the exact submitted build.

Run this checker before relying on the packet:

```bash
scripts/savi-appstore-privacy-labels-check.py
```

## Apple Baseline

Apple requires developers to disclose data collected by the app or third-party
partners unless the data qualifies for optional disclosure. Apple defines
collection as transmitting data off device in a way that the developer or
partners can access beyond what is necessary to service the request in real
time. Apple also says data processed only on device is not collected for App
Store privacy answers.

Source anchors:

- [Apple: App privacy details](https://developer.apple.com/app-store/app-privacy-details/)
- [Apple: Manage app privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy)
- [Apple: App privacy reference](https://developer.apple.com/help/app-store-connect/reference/app-privacy/)

## Current Build Scope

Current private-save-first Release/TestFlight assumptions:

- No required SAVI account.
- No live Supabase production collection.
- No live PostHog production analytics.
- No APNs/device-token collection.
- No live public social publishing.
- No public friend feed.
- No live metadata proxy owned by SAVI.
- No third-party SDKs linked in the current source.
- Local library is stored on device/app-group storage.
- Archive export/import is user-controlled.
- Help/Feedback is user-initiated and should not attach logs or saved content
  automatically.
- TestFlight feedback/crash diagnostics are handled through Apple's beta
  tooling, not a SAVI-owned SDK.

## Recommended Current Answer Path

If the exact submitted build still matches the current scope above, the likely
App Store Connect posture is:

| App Store Connect Area | Current Answer Draft |
|---|---|
| Does this app collect data from this app? | `No` |
| Tracking | `No` |
| Data linked to user | `No SAVI-collected data in current build` |
| Data used for tracking | `No` |
| Privacy Policy URL | Required public URL |
| Privacy Choices URL | Optional; can point to data-deletion/privacy page later |

Why: saved content, folders, search, Private Vault data, images, PDFs, and files
remain local/on-device unless the user explicitly exports them or chooses to
send feedback. The current source has no live Supabase/PostHog/APNs/ads SDK.

## Conservative Support Disclosure Path

If you decide the in-app Help & Feedback email should be disclosed even though
it is optional and user-initiated, use this conservative alternative:

| Data Type | Purpose | Linked To User | Tracking |
|---|---|---:|---:|
| Contact Info: Email Address | App Functionality / customer support | Yes | No |
| Diagnostics: Crash Data / Performance Data | App Functionality, only if received through user feedback or Apple/TestFlight reports | Possibly | No |

Use this path if SAVI later adds an in-app support form, automatic log
attachment, third-party crash SDK, or automatic diagnostic upload.

## What Not To Mark As Collected In Current Build

Do not mark these as developer-collected for the current local-only build unless
another code path starts transmitting them to SAVI or a third-party partner:

- saved URLs, notes, files, PDFs, images, screenshots, audio, or thumbnails,
- Private Vault content,
- folder names, tags, locked-folder state, or local learning signals,
- local search queries,
- local archive export contents,
- Photos/Files items imported through the Share Extension,
- Apple Intelligence/local folder suggestions,
- CloudKit/iCloud data while CloudKit is no-op/hidden in Release,
- TestFlight/Apple diagnostics that SAVI does not collect through its own code.

## Remote Metadata Notes

SAVI may contact a saved link's host or provider to load a title, preview, or
thumbnail. In the current build, that is not SAVI backend collection unless:

- SAVI routes metadata through its own proxy,
- SAVI stores fetched URL/domain metadata on its servers,
- SAVI sends saved URLs to analytics,
- SAVI uses a third-party SDK that collects link/user data.

If any of those happen, update this runbook, the privacy policy, App Store
privacy labels, and `Docs/Architecture/PrivacyDataInventory.md`.

## Future Answer Changes

Update App Store privacy labels before enabling any of these:

| Feature | Likely Data To Disclose |
|---|---|
| Sign in with Apple / accounts | User ID, email if provided, account/profile data |
| Supabase social | username, display name, public profile, follow graph, public links, likes, reports, blocks |
| Public publishing | public URLs, public titles/descriptions/domains/tags selected by the user |
| PostHog analytics | product interaction events, build, OS, device/performance tier; linked if account-enabled |
| Push notifications | APNs token, notification settings, account/device link |
| Metadata proxy | URLs/domains requested through SAVI infrastructure |
| Image search proxy | search query and selected image metadata if routed through SAVI/provider |
| iCloud backup | revisit if SAVI collects or processes anything beyond Apple's private user container |
| Crash/diagnostic SDK | crash/performance data, device/OS/build, possibly identifiers |
| Support form/log upload | email/contact info, diagnostics, optional user-provided screenshots/text |
| In-app purchases/subscriptions | purchase history and account entitlement data |

## Final Human Checklist

Before submitting privacy answers:

1. Confirm the exact archive build number.
2. Run `scripts/savi-preflight.sh`.
3. Run `scripts/savi-appstore-privacy-labels-check.py`.
4. Confirm no live Supabase/PostHog/APNs/social/CloudKit paths are enabled in
   Release unless privacy labels were updated.
5. Confirm no third-party SDK was added since the last SDK inventory check.
6. Confirm Help & Feedback still does not attach saved content or logs
   automatically.
7. Confirm the public privacy policy URL matches these answers.
8. Founder/legal owner confirms the final App Store Connect answers.

## Source Of Truth

- `Docs/AppStorePrivacyWorksheet.md`
- `Docs/Architecture/PrivacyDataInventory.md`
- `Docs/Architecture/AppStoreComplianceMatrix.md`
- `Docs/Architecture/ThirdPartySDKInventory.md`
- `Docs/Architecture/PrivacyManifestAudit.md`
- `Docs/Architecture/Runbooks/AppStoreSubmissionPacket.md`
