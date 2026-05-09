# SAVI TestFlight Readiness

Last updated: 2026-05-08

## Current Beta Posture

The first external TestFlight should ship as a private, local-first SAVI beta:

- Main app: `SAVI`
- App Store Connect name request: `SAVI: Save it now, Find it later.`
  Apple App Store names are capped at 30 characters, so use
  `SAVI: Save Now, Find Later.` if App Store Connect rejects the longer name.
- Main bundle ID: `com.altatecrd.savi`
- Share extension bundle ID: `com.altatecrd.savi.ShareExtension`
- App Group: `group.com.altatecrd.savi.shared`
- iCloud container: `iCloud.com.altatecrd.savi`
- Current local project build number: `34`
- Latest uploaded TestFlight build: `1.0 (34)` processing in App Store Connect
- Latest uploaded archive:
  `/Users/guest1/Documents/SAVI-iOS/build/qa/archives/SAVI-20260508-232717-b34.xcarchive`
- Supported devices for first beta: iPhone only
- Supported phone orientation for first beta: portrait
- Release/TestFlight social posture: Social Beta disabled
- Debug/local social posture: Social Beta remains enabled for development

The Release build hides or blocks friend feeds, public profiles, public folder
publishing, sample friend Ava, friend activity widgets, public folder badges,
public CloudKit social writes, and debug-only tooling. It includes a removable
sample library on fresh install so testers can immediately try folders, Search,
Explore, Private Vault, and clear-sample behavior. Core SAVI stays enabled:
share extension, folders, search, Explore for personal content, Face ID locks,
metadata, Apple Intelligence fallback, and archive export/import.

## Build Channels

SAVI uses one source tree with two installed channels:

- `SAVI` is the Release/TestFlight channel. It uses `com.altatecrd.savi`, shows as
  `SAVI`, hides Social Beta, hides debug/demo tooling, and is the build to
  archive/upload to App Store Connect.
- `SAVI Test` is the Debug/development channel. It uses
  `com.altatecrd.savi.personaldebug`, shows as `SAVI Test`, keeps Social Beta
  and debug/demo tooling visible, and is the app to use when building unfinished
  social features.

Do not add a third `SAVI Pilot` app yet. Add one only if we later need an
internal QA mirror that behaves like TestFlight but installs alongside both
existing channels.

## Iteration Speed Policy

- Default development loop: `scripts/savi-fast-dev-sim.sh`.
- Default simulator: iPhone 17.
- Default app: `SAVI Test` Debug only.
- Use `scripts/savi-fast-dev-sim.sh --reinstall` when testing Share Extension
  UI changes that may be cached by the simulator.
- Do not build Release, launch three simulators, archive, upload, or run the
  full matrix until a change is ready for a TestFlight gate.
- Full Release/TestFlight gate: update all target sims, then archive/upload.

## Apple-Side Checklist

Operational runbook:

- `Docs/Architecture/Runbooks/TestFlightOperations.md`
- `scripts/savi-testflight-ops-check.py`
- Share extension real-device QA:
  `Docs/Architecture/Runbooks/ShareExtensionRealDeviceQA.md`
- Share extension checker: `scripts/savi-share-extension-qa-check.py`
- Archive export/restore QA:
  `Docs/Architecture/Runbooks/ArchiveExportRestoreQA.md`
- Archive export/restore checker: `scripts/savi-archive-restore-check.py`

Created/verified in Apple Developer and App Store Connect:

- App ID: `com.altatecrd.savi`
- Share extension App ID: `com.altatecrd.savi.ShareExtension`
- App Group: `group.com.altatecrd.savi.shared`
- iCloud container: `iCloud.com.altatecrd.savi`
- App Store Connect app record: `SAVI: Save Now, Find Later.`
- Production signing/provisioning for the app and extension via Xcode automatic
  provisioning
- Latest App Store Connect upload succeeded; build `1.0 (34)` was uploaded and
  should be assigned to `SAVI Internal` after processing completes.
- Internal TestFlight group `SAVI Internal` exists and currently includes the
  active account holder `altatecrd@gmail.com` and
  `matti.lamminsalo@gmail.com`.
- App Store Connect invitations have been sent to `andreusbl@icloud.com` and
  `andreusbl@mac.com`; add them to `SAVI Internal` after they accept.
- Verify `luimi2k1@gmail.com` and `j.rodriguez28@icloud.com` as additional
  internal testers if they should receive the current build.
- Build-level `What to Test` notes should use the current friend-facing copy
  below for build `34`.

Still verify before upload:

- CloudKit private-container readiness if optional iCloud backup is included

You still need to provide:

- Privacy Policy URL
- Support URL or support email: use `1080solutionsA@gmail.com` unless a
  separate support alias is created.
- Beta feedback email: use `1080solutionsA@gmail.com`.
- App category
- Age rating
- Screenshots
- Confirm Beta description
- Confirm What to Test notes
- Export compliance answers

SAVI appears to use standard Apple/HTTPS/CloudKit encryption only, but export
compliance is a legal declaration. Do not set or submit the final export answer
until you confirm no custom/non-exempt encryption is used. The app and share
extension Info.plists include `ITSAppUsesNonExemptEncryption = NO` to match the
current code posture; confirm this in App Store Connect before upload.
Use the export compliance packet,
`Docs/Architecture/Runbooks/AppStoreExportCompliance.md`, and run
`scripts/savi-appstore-export-compliance-check.py` before relying on that
answer for a submitted build.

## Hardening Applied For Current Release Channel

- Release `SAVI` resolves to `com.altatecrd.savi`; Debug `SAVI Test` resolves to
  `com.altatecrd.savi.personaldebug`.
- Release Social Beta is hidden/blocked; Debug keeps it available for internal
  development.
- Release is iPhone-only and portrait-only for the first external beta, matching
  the UI surfaces actually designed and QA'd.
- The removable sample library is enabled in Release so external testers do not
  start from an empty app.
- Privacy manifests are bundled for both the app and share extension.
- Export-compliance plist key is present for both the app and share extension.
- `generate_project.py` now preserves the current Team ID, build number,
  iPhone-only target family, and sample-library build setting if the Xcode
  project is regenerated.

## Pilot Feedback Loop

- In-app Help & Feedback points to `1080solutionsA@gmail.com` with a prefilled bug
  report that includes app version, build number, channel, device, and iOS
  version.
- The in-app bug report does not attach logs or saved content automatically.
- If Mail is unavailable, the app copies `1080solutionsA@gmail.com` so testers can
  paste it into any email client.
- TestFlight screenshot/comment feedback remains the primary Apple beta channel
  and should be checked in App Store Connect after each internal testing pass.

## Current TestFlight Metadata Copy

App name:

Requested: `SAVI: Save it now, Find it later.`

30-character fallback: `SAVI: Save Now, Find Later.`

Beta description:

SAVI is a pocket organizer for the useful things you find across your digital
life: links, screenshots, PDFs, videos, Wi-Fi codes, notes, files, and little
ideas you may want again later.

Add SAVI to the iOS Share Sheet once, then save from Safari, YouTube, Photos,
Files, Messages, and the apps you already use. SAVI helps name each save, add
smart tags, choose a folder, and make it easy to search by title, note, tag,
folder, source, file type, or the tiny clue you remember.

This beta is focused on the everyday basics: quick saving, search, folders,
Private Vault, archive backup, and feedback. Explore is a fun way to browse
your own saved favorites, and later it can include great things curated by
friends too.

Thank you for helping shape SAVI early. When something feels confusing, broken,
slow, surprisingly nice, or just a little off, please send Andreus a note
directly or email 1080solutionsA@gmail.com.

What to Test:

Try SAVI the way you would naturally use it:

1. Open the welcome flow and pin SAVI in your iOS Share Sheet.
2. Save a normal link, YouTube video, screenshot, image, PDF/file, and plain
   text from the Share Sheet.
3. Open SAVI and check that the save appears with a useful title, thumbnail,
   smart tags, and a sensible folder.
4. Try Home, Search, Explore, Folders, Private Vault, preview opening, archive
   export, and Help & Feedback.
5. Send Andreus feedback personally or email 1080solutionsA@gmail.com. Bugs,
   screenshots, confusing moments, and small “this feels weird” notes are all
   welcome.

Thanks for helping build SAVI. You are seeing it early, and your notes will
help make it feel better for everyone.

Recommended screenshot order:

1. Welcome/onboarding: `Save it now. Find it later.`
2. Share extension: polished `Save to SAVI` flow with YouTube/video metadata.
3. Home: recent saves plus Your Folders/LOLZ cover visible.
4. Search: clear results with tags/folders.
5. Explore: curated saved favorites and soon-friends teaser.
6. Profile: Help & Feedback, backup/export, and setup controls.

## Suggested TestFlight Review Notes

Social Beta is disabled in this build. A removable sample library is included
on first launch with practical examples first, then private and fun examples.
Testers can save links, files, images, PDFs, notes, and screenshots through the
iOS Share Sheet, organize saves into folders, search/refine their library,
browse personal saved links in Explore, lock private folders with Face
ID/passcode, export or restore a full local archive, and report pilot feedback
from Profile > Help & Feedback. Public friend feeds and public sharing controls
are hidden for this beta while moderation, reporting, and terms are prepared.

## Production Build Flow

1. Build scheme `SAVI`.
2. Configuration `Release`.
3. Destination `Any iOS Device`.
4. Confirm Release resolves to `com.altatecrd.savi`, not `com.altatecrd.savi.personaldebug`.
5. Confirm `SAVIShareExtension` embeds as `com.altatecrd.savi.ShareExtension`.
6. Archive from Xcode.
7. Upload to App Store Connect.
8. Add internal testers first.
9. Submit the first external group to TestFlight App Review.

## Verification Checklist

- Fresh install: onboarding, Home sample library, Search, Explore, Folders, Profile.
- Share extension: URL, YouTube, TikTok, Instagram, X/Twitter, text, image, PDF, generic file.
- Share extension real-device QA: run the SAVI Share Extension Real-Device QA
  flow on Release `SAVI`, including Safari, Photos, Files, a video/social link,
  and a poor-network metadata fallback.
- Feedback: Profile > Help & Feedback opens a prefilled bug email or copies
  `1080solutionsA@gmail.com` if Mail is unavailable.
- Metadata/AI: save remains instant if metadata or Apple Intelligence times out.
- Privacy: locked folders and Private Vault stay hidden until Face ID/passcode.
- Archive: export warns about private content, restore does not publish anything.
- Archive export/restore QA: run the SAVI Archive Export And Restore QA flow on
  Release `SAVI`, including full archive export, compact JSON backup export,
  cancel states, invalid-file restore, and fresh-install restore.
- Offline: app remains usable without network.
- Large library: Home/Search scroll smoothly.
- Light/dark: no unreadable cards, folder names, timeline text, or sheets.

## References

- [TestFlight overview](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/)
- [Invite external testers](https://developer.apple.com/help/app-store-connect/test-a-beta-version/invite-external-testers)
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [App privacy details](https://developer.apple.com/app-store/app-privacy-details/)
- [Privacy manifests](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files)
- [Export compliance](https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance/)
- [Account deletion guidance](https://developer.apple.com/support/offering-account-deletion-in-your-app/)
