# SAVI Current Handoff - 2026-05-07

Use this document as the first thing to read in any new SAVI Codex chat.

## Start Next Chat With This

```text
Read /Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/2026-05-07-savi-current-handoff.md first, then continue SAVI work from there.
```

Ask the new chat to summarize this file before it edits anything. Other chats do
not automatically know this conversation; they need this path explicitly.

## Active Repo

- Current native iOS app: `/Users/guest1/Documents/SAVI-iOS`
- Main Xcode project: `/Users/guest1/Documents/SAVI-iOS/SAVI.xcodeproj`
- Do not use `/Users/guest1/Documents/SAVI` or `/Users/guest1/Documents/SAVI `
  unless the user explicitly asks for the old web/design prototype.
- Native app entry flow: `SAVIApp.swift -> ContentView -> NativeSaviRootView`
- Share extension UI: `SAVIShareExtension/ShareViewController.swift`
- Share extraction/metadata path: `SAVIShareExtension/ShareItemExtractor.swift`
- Main app data/metadata path: `SAVI/Core/SaviCore.swift`

## Build Channels

| Channel | Bundle ID | Configuration | Purpose | Social |
|---|---|---|---|---|
| `SAVI` | `com.altatecrd.savi` | Release | TestFlight/App Store candidate | Hidden/off |
| `SAVI Test` | `com.altatecrd.savi.personaldebug` | Debug | Internal development/testing | Visible/on |

Production Apple setup currently uses:

- Team: `ANDREUS BELLO-LIF - 887JW5T2M8`
- App ID: `com.altatecrd.savi`
- Share extension App ID: `com.altatecrd.savi.ShareExtension`
- App Group: `group.com.altatecrd.savi.shared`
- iCloud container: `iCloud.com.altatecrd.savi`

## Current TestFlight State

- Latest uploaded build: `SAVI 1.0 (14)`
- Upload time: 2026-05-07 around 01:36 Europe/Madrid.
- Upload command completed successfully with `Uploaded SAVI` and
  `** EXPORT SUCCEEDED **`.
- App Store Connect reported the uploaded package was processing.
- Build archive:
  `/Users/guest1/Documents/SAVI-iOS/build/qa/archives/SAVI-20260507-013124-b14.xcarchive`
- Upload log:
  `/Users/guest1/Documents/SAVI-iOS/build/qa/logs/SAVI-export-upload-build14.log`

Next App Store Connect checks:

- Confirm build `1.0 (14)` finished processing.
- Assign build `1.0 (14)` to internal testers.
- Verify these tester emails are in the right App Store Connect/TestFlight group:
  - `matti.lamminsalo@gmail.com`
  - `andreusbl@icloud.com`
  - `andreusbl@mac.com`

## Latest Fix: Build 14 Metadata Hotfix

User reported the share sheet no longer seemed to pull metadata, and metadata
also did not repair after opening the app.

Build 14 fixed:

- Release/TestFlight metadata repair had been disabled and is now re-enabled.
- `LinkPresentation` metadata is enabled in Release where supported.
- Share extension metadata fetch timeout increased from `2.2s` to `3.8s`.
- Share extension JSON/HTML request timeout increased from `2s` to `3.5s`.
- Metadata refresh is now device-aware through `SaviPerformancePolicy`.
- iPhone 11/legacy devices repair only tiny metadata batches at launch/foreground.
- Stale metadata repair no longer chains through the whole library after launch.
- Share-import/deeplink/pasteboard saves can still trigger one follow-up repair.
- Metadata logs now print `data-url` for base64 thumbnails instead of dumping huge
  image strings.

Verification already done:

- `git diff --check` passed before build.
- Release generic iPhoneOS no-sign build succeeded.
- Release iPhone 11 simulator build/install/launch succeeded.
- iPhone 11 launch logs showed `perfTier=legacy`, one stale metadata repair, and
  no repair chain.

Important logs:

- `/Users/guest1/Documents/SAVI-iOS/build/qa/logs/SAVI-build14-metadata-hotfix-release-iphoneos-nosign.log`
- `/Users/guest1/Documents/SAVI-iOS/build/qa/logs/SAVI-build13-metadata-hotfix-iphone11-launch.log`
- `/Users/guest1/Documents/SAVI-iOS/build/qa/logs/SAVI-archive-build14-metadata-hotfix.log`
- `/Users/guest1/Documents/SAVI-iOS/build/qa/logs/SAVI-export-upload-build14.log`

Detailed changelog:

- `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-07.md`
- `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-06.md`

## Current Dirty Worktree Warning

The repo is intentionally dirty from many SAVI changes. Do not run destructive
git commands and do not revert unrelated files. Work with the existing state.

Common dirty areas include:

- `SAVI/Core/SaviCore.swift`
- `SAVIShareExtension/ShareItemExtractor.swift`
- `SAVIShareExtension/ShareViewController.swift`
- multiple SwiftUI screen files under `SAVI/Views/`
- docs, changelogs, scripts, entitlements, and project settings

Use `git status --short` before editing. Keep new changes tightly scoped.

## Product Direction To Preserve

- SAVI should feel premium, playful, fast, and useful: save anything now, find it
  later instantly.
- Release/TestFlight should keep Social hidden.
- Debug/internal `SAVI Test` can keep Social visible.
- Light mode is the best visual target; do not break it.
- Dark mode should remain legible.
- Home uses the compact editorial timeline with a fluid rail.
- Search should be compact and aligned with Home, not a second dashboard.
- Explore in Release is personal-first, with no active friends/social feed.
- The older/current app icon is preferred; do not revive the rejected new share-S
  icon without explicit user request.
- Folder colors should stay colorful, not all purple/lavender.
- Sample library is enabled for TestFlight onboarding.

## Pending / Likely Next Work

Highest priority checks:

- Confirm TestFlight build `1.0 (14)` processing is complete.
- Assign or verify internal testers on build `1.0 (14)`.
- Test real-device share sheet metadata on:
  - normal URL,
  - YouTube,
  - TikTok/Instagram/X if available,
  - image/screenshot,
  - PDF/file,
  - plain text.
- Confirm metadata appears in the share sheet when possible and repairs after app
  launch when it arrives late.
- On Matti's iPhone 11, confirm build `14` launches, Home scrolls, and shared
  links no longer stay generic.

Known open areas from prior work:

- Full archive export/import should show a clear share/file exporter flow.
- Share extension folder/tag UI was redesigned toward a visible two-column folder
  grid; verify it still feels clean on small phones.
- Main/Test simulator data may differ; if `SAVI Test` looks wrong, clone main
  simulator data with `scripts/savi-clone-main-to-test-sim.sh`.

## Useful Commands

```bash
git status --short
git diff --check
xcodebuild -project SAVI.xcodeproj -scheme SAVI -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
scripts/savi-install-both-sim.sh --no-launch
scripts/savi-clone-main-to-test-sim.sh
CONFIGURATION=Release SCHEME=SAVI Tools/savi-production-ui-qa.sh
```

## Handoff Rule

If a new chat seems confused, have it read this file again, then read:

```text
/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-07.md
```

Those two files are the current source of truth for where this chat left off.
