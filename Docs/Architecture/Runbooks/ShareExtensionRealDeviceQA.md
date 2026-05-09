# SAVI Share Extension Real-Device QA

Use this runbook before handing a build to testers when the change touches the
share extension, metadata, folder/tag suggestions, app-group import, onboarding
Share Sheet setup, thumbnails, performance policy, or TestFlight release
readiness.

Run this checker after changing the runbook or before a release handoff:

```bash
scripts/savi-share-extension-qa-check.py
```

## First Rule

The Share Sheet is a core SAVI promise. A build is not ready for wider testing
if a real iPhone cannot save from Safari, Photos, Files, and at least one video
app without trapping the user.

Do not ask testers to send private documents, IDs, passwords, recovery codes,
Private Vault content, or exported archives while testing this flow. Use fake
or disposable examples for PDFs, screenshots, images, and files.

## Device Matrix

Minimum before TestFlight handoff:

- One modern iPhone for the polished path.
- One older phone if available, preferably iPhone 11 / iOS 17.4-class hardware.

Simulator-only QA is acceptable for quick UI iteration, but it does not replace
real-device Share Sheet QA because extension presentation, provider metadata,
Files handoff, Photos permissions, memory pressure, and TestFlight packaging can
behave differently on device.

## Setup

1. Install the exact TestFlight or Release build being tested.
2. Open SAVI once.
3. Complete onboarding or skip to Home.
4. Pin SAVI in the iOS Share Sheet.
5. Confirm SAVI appears near the front of the Share Sheet.
6. Keep at least one network-on pass and one poor-network/offline pass.
7. Test with Release `SAVI` / `com.altatecrd.savi`, not only Debug
   `SAVI Test`.

If the tester still sees an old build, use
`Docs/Architecture/Runbooks/TestFlightOperations.md` before continuing.

## Required Save Matrix

Run every row. Each save should complete even if metadata is missing, slow, or
blocked by the source app.

| Source | Example | Expected behavior |
|---|---|---|
| Safari URL | normal article/product page | suggested title/folder/tags appear; save completes; item opens back to the URL |
| YouTube | direct video page | video/domain metadata or safe fallback appears; remote thumbnail can load later |
| TikTok/Instagram/X | public post/share URL | save does not fail if metadata is limited; domain/title fallback is usable |
| Photos screenshot | fake screenshot with useful text | type/source read as image/Photos; tags include screenshot-style intent where detected |
| Photos image | non-private photo | image preview imports; no remote metadata dependency |
| Files PDF | fake/sample PDF | PDF/file save completes; preview or file fallback opens from item detail |
| Files generic file | harmless test file | file import completes; filename/type fallback is readable |
| Plain text | copied note or selected text | text save creates a useful title/note and tags |
| Offline URL | any URL with network disabled | save still completes with fallback metadata |

Use disposable assets for document/image/file tests. Never use real IDs,
insurance cards, bank records, passwords, or private customer data.

## UX Pass Criteria

The share extension passes only if:

- Extension opens quickly enough to feel immediate.
- Save button is always visible and reachable.
- Auto-suggested folder is visible without hiding manual control.
- Manual folder selection is easy to change and not clipped.
- Suggested tags are readable, removable, and addable.
- Keyboard can be dismissed without accidentally opening a card behind it.
- Metadata loading does not block Save.
- Apple Intelligence or local folder brain timeout does not block Save.
- Cancel exits cleanly without creating a partial save.
- Completed save imports into the main app after foregrounding SAVI.
- Home, Search, and the selected folder can find the new item.
- Private Vault or locked folders stay locked unless the user deliberately
  chooses/unlocks them.

## Metadata Expectations

Metadata is a bonus, not a dependency.

Pass:

- provider title, thumbnail, and domain load normally,
- partial metadata loads and SAVI still saves,
- fallback title/source/type appears when metadata is unavailable,
- metadata repair can improve the item after save without blocking scrolling.

Fail:

- Save is disabled while metadata loads,
- extension spins forever,
- item is lost when metadata fails,
- source app memory pressure kills the extension,
- metadata fetch leaks private file contents or screenshots.

## Main-App Import Checks

After each share:

1. Open SAVI.
2. Confirm the item appears on Home or in the selected folder.
3. Search by one obvious term from the title/source/tag.
4. Open item detail.
5. Tap the primary preview/open action.
6. Confirm the source, file type, and folder are sensible.

For images, PDFs, and files, verify the preview or file fallback is obvious.
For videos/social links, verify the item opens the original URL rather than a
fake or bundled copy.

## Poor-Network Pass

Repeat at least one URL and one video/social save with poor network or Airplane
Mode:

- Share extension still opens.
- Save still completes.
- Item imports into SAVI.
- Fallback title/source/tag state is understandable.
- App does not retry metadata so aggressively that Home scrolling becomes
  sluggish.

## Failure Triage

If a share fails:

1. Record build number, device, iOS version, source app, item type, and whether
   network was available.
2. Submit TestFlight feedback immediately after reproducing if safe.
3. Do not attach private saved content.
4. Use `Docs/Architecture/Runbooks/CrashAndPerformanceTriage.md` if the app or
   extension crashes, freezes, or becomes slow.
5. Use `Docs/Architecture/Runbooks/TestFlightOperations.md` if the tester may
   be on an old build.

Allowed report details:

- source app such as Safari, Photos, Files, YouTube, TikTok, Instagram, or X,
- item type such as URL, video link, image, screenshot, PDF, file, or text,
- folder chosen,
- high-level failure type such as save disabled, metadata stalled, import
  missing, preview missing, or crash.

Forbidden report details unless the tester deliberately chooses to share:

- private note text,
- document contents,
- private filenames,
- IDs, insurance, bank, password, or recovery-code screenshots,
- Private Vault contents,
- exported archives.

## Release Gate

Block wider TestFlight or App Store submission if:

- Safari URL save fails,
- Photos image/screenshot save fails,
- Files PDF save fails,
- Save depends on metadata completing,
- completed shares do not import into the main app,
- extension UI clips critical controls on an iPhone 11-class screen,
- a real-device extension crash reproduces on Release.

Ship only to internal investigation if:

- a provider blocks metadata but fallback save works,
- one social app has limited thumbnails but the URL saves and opens,
- metadata repair is delayed but the item remains searchable,
- Debug/SAVI Test fails but Release works.

## Verification Commands

```bash
scripts/savi-share-extension-qa-check.py
scripts/savi-crash-performance-check.py
scripts/savi-preflight.sh
scripts/savi-preflight.sh --release-build
```

Use the visual matrix when share-extension UI, onboarding Share Sheet setup, or
card layout changed:

```bash
CONFIGURATION=Release SCHEME=SAVI Tools/savi-production-ui-qa.sh
```

## Source Anchors

- `Docs/ProductionReadiness.md`
- `Docs/TestFlightReadiness.md`
- `Docs/Architecture/Runbooks/AppStoreSubmissionPacket.md`
- `Docs/Architecture/Runbooks/TestFlightOperations.md`
- `Docs/Architecture/Runbooks/CrashAndPerformanceTriage.md`
