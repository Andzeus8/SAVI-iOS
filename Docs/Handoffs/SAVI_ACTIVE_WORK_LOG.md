# SAVI Active Work Log

Use this file as the shared coordination surface when multiple Codex chats are
working in `/Users/guest1/Documents/SAVI-iOS` at the same time.

## Coordination Rule

- Before editing, run `git status --short` and read this file.
- Add an entry with the files you expect to touch.
- Avoid files another active chat has claimed unless the change is unavoidable.
- Never revert unrelated changes from another chat.
- After verification, update your entry with status and test notes.

## Active / Recent Entries

### 2026-05-07 14:39 CEST - Build 18 candidate cleanup

- Owner: current Codex chat
- Status: completed at 2026-05-07 14:52 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-07.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Design/SampleLibrarySources.md`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI.xcodeproj/project.pbxproj`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Info.plist`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Core/SaviCore.swift`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Views/Components/AppComponents.swift`
  - `/Users/guest1/Documents/SAVI-iOS/SAVIShareExtension/Info.plist`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Assets.xcassets/onboarding-search-real.imageset`
- Notes:
  - Merge current dirty work into one build `18` candidate without uploading to TestFlight.
  - Preserve other chat changes in `SaveAndEditSheets.swift` and `ShareViewController.swift`.
- Result:
  - Removed unused onboarding/share setup demo code and the unreferenced `onboarding-search-real` generated asset.
  - Made Share Sheet practice image detection work for the real share-extension import path by matching the practice file/title, not only the deterministic direct-save id.
  - Bumped app/share extension build settings to `18` and changed both `Info.plist` files to use `$(CURRENT_PROJECT_VERSION)`.
  - Clean-installed both simulator channels on iPhone 17 Pro `C99532A0-7EE8-4078-B821-703387BCFBD5`; `SAVI`, `SAVI Share`, `SAVI Test`, and `SAVI Test Share` all report `1.0 (18)`.
  - `git diff --check` passed.
  - Release generic iPhoneOS no-sign build passed.
  - No TestFlight upload was performed.

### 2026-05-07 14:05 CEST - First-run personality and share setup polish

- Owner: current Codex chat
- Status: completed at 2026-05-07 14:14 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Views/Components/AppComponents.swift`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Core/SaviCore.swift`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Services/LegacyAndUtilities.swift`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Assets.xcassets/share-setup-practice-savi-first-card.imageset`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Assets.xcassets/folder-cover-memes-laughing-kid.imageset`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Assets.xcassets/onboarding-share-extension-real.imageset`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Design/SampleLibrarySources.md`
- Notes:
  - Merging into the existing dirty onboarding component; do not revert the other chat's share-extension or save-sheet work.
  - Use generated/licensed-safe artwork for the meme folder cover, not a recognizable copyrighted meme photo.
- Result:
  - Updated onboarding story/copy, generated the share-extension suggestion visual, refreshed the folders visual, and replaced the practice image with an `I love SAVI` poster.
  - Added generated `Memes & LOLs` folder cover and bumped folder layout version so default/no-cover installs receive it without overwriting custom covers.
  - Updated Share Sheet practice save metadata to source `Photos`, type image, and sample/practice tags.
  - `git diff --check` passed.
  - Release iPhoneOS no-sign build passed.

### 2026-05-07 13:24 CEST - Folder editor online image flow

- Owner: current Codex chat
- Status: completed at 2026-05-07 13:39 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Views/Save/SaveAndEditSheets.swift`
  - `/Users/guest1/Documents/SAVI-iOS/AGENTS.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
- Notes:
  - Avoiding `/Users/guest1/Documents/SAVI-iOS/SAVI/Views/Components/AppComponents.swift`; another chat has onboarding changes there.
  - Avoiding `/Users/guest1/Documents/SAVI-iOS/SAVIShareExtension/ShareViewController.swift`; another chat has share-extension changes there.
- Result:
  - Folder editor `Find image online` now opens the configured in-app image search or a fallback helper when the proxy is missing.
  - Added broader folder color swatches and clearer cover/color/symbol copy.
  - `git diff --check` passed.
  - Release iPhoneOS no-sign build passed.
