# SAVI Handoff - 2026-05-06

Use this document as the first thing to read in a new Codex chat.

## Start Here

- Active app repo: `/Users/guest1/Documents/SAVI-iOS`
- Do not edit `/Users/guest1/Documents/SAVI` or `/Users/guest1/Documents/SAVI ` unless the user explicitly asks for the old web/design prototype.
- Main Xcode project: `/Users/guest1/Documents/SAVI-iOS/SAVI.xcodeproj`
- Native app entry: `SAVIApp.swift -> ContentView -> NativeSaviRootView`
- Share extension UI: `SAVIShareExtension/ShareViewController.swift`

The user wants SAVI to feel playful, premium, useful, and fast. The app should make it obvious: save anything now, find it later instantly.

## Build Channels

There are two app channels from the same source tree.

| Channel | Bundle ID | Configuration | Purpose | Social |
|---|---|---|---|---|
| `SAVI` | `com.altatecrd.savi` | Release | TestFlight/App Store candidate | Hidden/off |
| `SAVI Test` | `com.altatecrd.savi.personaldebug` | Debug | Internal development/testing | Visible/on |

Rules:

- `SAVI` is the main/TestFlight-safe channel.
- `SAVI Test` is the internal social/debug channel.
- Do not fork logic between them unless the release gate already controls it.
- After meaningful code/UI changes, build/install both simulator channels when practical.
- If Test looks different from main, first check data containers. The source code is shared, but app data/prefs differ.
- Main simulator data can be cloned into Test with `scripts/savi-clone-main-to-test-sim.sh`.
- App Store Connect app record exists as `SAVI: Save Anything`; the installed
  display name remains `SAVI`.
- Apple Developer team used for production IDs: `ANDREUS BELLO-LIF - 887JW5T2M8`.
- Production Apple IDs:
  - App ID: `com.altatecrd.savi`
  - Share extension App ID: `com.altatecrd.savi.ShareExtension`
  - App Group: `group.com.altatecrd.savi.shared`
  - iCloud container: `iCloud.com.altatecrd.savi`

Useful commands:

```bash
scripts/savi-install-both-sim.sh --no-launch
scripts/savi-clone-main-to-test-sim.sh
CONFIGURATION=Release SCHEME=SAVI Tools/savi-production-ui-qa.sh
xcodebuild -project SAVI.xcodeproj -scheme SAVI -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

## Current Worktree State

At the time this handoff was created, the worktree already had unrelated in-progress changes:

- `Docs/CHANGELOG.md`
- `Docs/ChangeLog/2026-05-05.md`
- `Docs/ChangeLog/2026-05-06.md`
- `SAVI/Core/SaviCore.swift`
- `SAVI/Services/LegacyAndUtilities.swift`
- `SAVI/Views/Items/ItemViews.swift`
- `SAVI/Views/Profile/ProfileAndFriends.swift`
- `SAVI/Views/Root/NativeSaviRootView.swift`

Do not reset or discard these. Work with the dirty tree and keep edits tightly scoped.

## Product Direction And Recent Decisions

- Light mode is currently the best visual target. Do not break it.
- Dark mode has been polished for better contrast and must remain legible.
- Home uses a compact editorial timeline with a fluid left rail and folder-colored dots.
- Search should feel like the same design language as Home: compact, clear, not a giant filter wall.
- Explore in Release should be personal-first. Social/friends should not be active in TestFlight.
- Profile was cleaned up to explain SAVI better and keep beta/social copy less messy.
- The preferred app icon is the older/current icon. The newer share-S icon concept was rejected and should not be used.
- Folder colors should stay fun and colorful, but not drift into all-purple/lavender.
- Folder names and metadata should not overpower titles.
- Bottom plus is the main action and should remain visually primary.

## Sample Library State

The sample library is enabled for TestFlight so new users immediately understand the app. It has been heavily curated around utility, emotional connection, health/research hooks, AI usefulness, memes, places, and private/life-admin examples.

Current desired first-card direction:

1. Airbnb door code + Wi-Fi as a fake iPhone screenshot/chat from Photos, tagged with `screenshot`.
2. Mom's lasagna sauce voice note as an audio example with a strong audio-file thumbnail.
3. Practical/lifesaving utility content such as CPR or other high-value links.
4. Parasite medication and cancer remission? as a medically neutral research hook.
5. Does your microbiome control your thoughts? as a gut-brain/parasite curiosity hook.
6. Useful AI agent/prompt content, but not too high if it weakens the emotional opening.
7. Jennifer's ramen recommendation with a real ramen-style thumbnail.
8. A/C warranty screenshot or another practical screenshot.
9. Numa Numa or another classic funny internet video.
10. Private/life-admin examples later enough that the first screen does not feel like paperwork.

Important sample-library constraints:

- Do not bundle copyrighted YouTube/meme thumbnails as app assets. Use real public YouTube URLs and remote metadata/thumbnails.
- Fake documents must be obviously sample-only and use invented data.
- Health content must be framed as research/questions, not medical advice or treatment claims.
- Sample times should be relative to first launch so new users see fresh examples like `2h ago`, not stale development dates.
- If changing seed content, bump the native sample seed version and make sure sample restore/clear still works.

## TestFlight Posture

The first TestFlight build should be conservative:

- Release `SAVI` hides Social/friends/public publishing.
- Debug `SAVI Test` can keep Social tools.
- Sample library stays enabled for onboarding.
- App should be iPhone-only and portrait-only for first beta unless a separate QA pass changes that.
- Apple-side setup still requires the developer's account work: App Store Connect record, privacy policy URL, support URL/email, beta feedback email, age rating, screenshots, export compliance confirmation, signing/provisioning, and upload.
- If iCloud/App Group signing blocks upload, consider a local-only beta fallback with archive export/import and Social hidden.

## Known Areas To Verify

- Full archive export/import: user reported export appeared to do nothing. It should show a share/file exporter flow. Needs verification and likely UX loading/progress polish.
- Share extension folder/tag UI: current high-priority pending task.
- Real-device share extension: must be tested with URL, YouTube, screenshot/image, PDF/file, and plain text before external TestFlight.
- Private Vault: locked/private items should stay hidden until Face ID/passcode unlock in real use.
- Sample library clear/restore: clearing samples should remove only demo items, never user saves.
- Main/Test sync: if `SAVI Test` looks wrong, clone data from main simulator before assuming UI code drift.

## Pending Task: Share Extension Folder And Tag Picker

User request: when sharing from anywhere, the share sheet should show all folder options clearly. The current horizontal folder picker is clipped and requires sliding sideways. The user wants the older/easier feeling where folders are laid out.

Decision-complete plan:

- Edit `SAVIShareExtension/ShareViewController.swift`.
- Keep the smart selected-folder summary at the top.
- Replace the visible horizontal folder strip with a two-column folder grid shown by default.
- Keep `Auto` as the first option.
- Show all folders in a vertical scroll, not a horizontal scroll.
- Manual folder selection must remain protected from late metadata/AI overwrites.
- Keep the current auto-selection pipeline and folder-source tracking.
- Make folder tiles compact, readable, and non-clipped:
  - icon/color cue,
  - folder name up to two lines,
  - selected check state,
  - recommended/smart indicator when relevant,
  - minimum 44 pt tap target.
- Replace cramped horizontal tag scrollers with wrapping smart tag chips:
  - selected tags first,
  - suggested `+ tag` chips after,
  - `More tags` reveals additional suggestions and manual tag text field.
- Preserve notes behavior, save behavior, metadata loading, platform/source tags, and pending-share storage.
- Test on iPhone SE, standard iPhone, and Pro Max sizes in light/dark if practical.

Current implementation facts from inspection:

- `ShareViewController` currently has:
  - `folderSummaryCard`
  - `folderQuickScrollView`
  - `folderQuickRow`
  - `folderGridStack`
  - `folderGridExpanded = false`
  - selected/suggested tag scroll rows
- `configureView()` adds the summary card, horizontal quick strip, and a hidden grid.
- `rebuildFolderButtons()` already builds a two-column `folderGridStack`, but it is hidden by default and paired with the horizontal quick strip.
- `toggleFolderGrid()` currently changes the folder change button between `More` and `Done`.
- Manual folder taps set `folderSelectionSource = .manual`, which should be preserved.

## Coding Guardrails

- Use `apply_patch` for manual edits.
- Do not use destructive git commands.
- Do not revert user or previous-agent changes unless explicitly asked.
- Keep changes scoped and avoid broad redesigns unless requested.
- For bigger visual changes, create a rollback archive under `Docs/Design/...` first.
- Prefer existing theme tokens and local patterns.
- Build after implementation when feasible.

## Suggested First Message In A New Chat

```text
Read /Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/2026-05-06-savi-handoff.md first. Continue from the pending share extension folder/tag picker redesign. Use /Users/guest1/Documents/SAVI-iOS, not the old SAVI prototype.
```
