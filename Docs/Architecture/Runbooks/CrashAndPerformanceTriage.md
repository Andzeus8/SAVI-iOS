# SAVI Crash And Performance Triage

Use this when a tester says SAVI crashed, froze, would not scroll, felt slow, or
behaved differently on an older phone. It is designed around the problems SAVI
already saw on iPhone 11 / iOS 17.4, while still applying to newer devices.

Run this checker after changing triage docs or before a release handoff:

```bash
scripts/savi-crash-performance-check.py
```

## First Rule

Do not ask testers to email private documents, IDs, passwords, recovery codes,
Private Vault content, screenshots of sensitive content, or exported archives.
Use TestFlight feedback and privacy-safe reproduction notes first.

## Triage Categories

Classify every report into one primary bucket:

- Launch crash: app closes before Home is usable.
- Foreground crash: app launches, then crashes after returning from background.
- Share extension failure: save sheet fails, stalls, or does not import into SAVI.
- Interaction freeze: app is visible but taps or tab changes stop responding.
- Scroll jank: Home, Search, Explore, Folders, or Profile scrolls slowly or
  stutters.
- Metadata/thumbnail jank: thumbnails visibly pop, reload, or block scrolling.
- Export/import failure: archive export or restore does not complete.
- Visual layout issue: clipped text, hidden buttons, overlapping cards, bad dark
  mode, or bottom tab covering content.

## Minimum Report To Collect

Ask for:

- Tester email.
- Build number shown in TestFlight.
- Device model.
- iOS version.
- Exact screen: Home, Search, Explore, Folders, Profile, share extension, or
  onboarding.
- What they were doing immediately before the issue.
- Whether it happens every time or only sometimes.
- Whether deleting and reinstalling from TestFlight changes it.
- TestFlight feedback submission immediately after reproducing, if safe.

Do not request saved item contents. If a screenshot is needed, ask the tester to
blur or avoid private content.

## TestFlight Feedback Path

If the tester can reproduce:

1. Reproduce the issue on the affected build.
2. Immediately open TestFlight.
3. Select SAVI.
4. Send feedback with a short note such as `Home scroll freezes on iPhone 11`.
5. Include screenshot or screen recording only if it does not reveal private
   content.

Then in App Store Connect:

1. Open Apps > SAVI > TestFlight.
2. Open Feedback or Crashes for the relevant build.
3. Confirm the report is attached to the same build the tester installed.
4. Record build, device, iOS, and symptom in the active work log or changelog.

Use `Docs/Architecture/Runbooks/TestFlightOperations.md` if the tester is still
on an old build.

## Local Reproduction Order

Before writing a speculative fix, try to reproduce in this order:

1. Run `scripts/savi-status-report.py` to confirm local build, bundle IDs, and
   latest uploaded build.
2. Run `scripts/savi-preflight.sh` to catch doc/config drift.
3. Build the Release app if the report came from TestFlight:
   `scripts/savi-preflight.sh --release-build`.
4. Reproduce on the closest simulator:
   - iPhone 11 or iPhone 11-class simulator for legacy reports.
   - iPhone 17 for modern-device regressions.
5. Compare Home, Search, Explore, Folders, and Profile.
6. Test fresh install and existing-data launch.
7. Test offline launch if metadata/network is suspected.

For visual layout reports, run:

```bash
Tools/savi-production-ui-qa.sh
```

For SwiftUI scroll or startup profiling, use the local iOS performance profiling
workflow and save traces under `build/qa/` or another ignored `build/` path.

## Known iPhone 11 Risk Areas

Treat these as first suspects on older phones:

- launch-time CloudKit or iCloud initialization,
- custom `UTType` / LaunchServices behavior on iOS 17,
- heavy Home thumbnail decode work,
- remote image retry storms,
- too many rich cards appearing at once,
- large SwiftUI view invalidation during scroll,
- metadata repair work running on foreground,
- share extension import work happening on the main thread,
- animated thumbnail placeholder replacement,
- expensive folder/sample repair during first launch.

Current architecture expectations:

- CloudKit stays no-op/hidden in Release until production entitlements are
  verified.
- Metadata, thumbnails, and repair work must never block launch or scrolling.
- Release social stays hidden.
- Share extension saves should be usable even if metadata or Apple Intelligence
  times out; no save should depend on metadata or Apple Intelligence times out
  handling being perfect.

## Severity Rules

Block external TestFlight or App Store submission if:

- launch crash reproduces on Release,
- real-device share extension cannot complete a basic save,
- Home cannot scroll on supported devices,
- Private Vault content leaks while locked,
- archive export/import corrupts data,
- app crashes when opening Profile/backup/privacy controls.

Ship as internal-only investigation if:

- issue affects one tester but no crash/feedback report is available,
- performance is degraded but all core flows still work,
- only Debug/SAVI Test is affected,
- issue is isolated to experimental social paths hidden in Release.

## Privacy-Safe Debug Notes

Allowed in bug reports:

- app version/build,
- device model,
- iOS version,
- performance tier,
- screen name,
- item type such as link/image/pdf/video,
- high-level source such as Safari/Photos/Files/YouTube,
- timing bucket such as launch under 2 seconds or scroll freezes after 10 cards.

Forbidden in bug reports unless the user deliberately chooses to share:

- private note text,
- document contents,
- filenames containing private information,
- screenshots with IDs/passwords/private documents,
- Private Vault contents,
- recovery codes,
- raw clipboard contents,
- exported archives.

## Fix Discipline

- Fix one suspected cause at a time when possible.
- Prefer targeted runtime policy changes over degrading every device.
- Keep modern iPhones polished; do not force legacy performance mode globally.
- If batching/lazy loading is needed, avoid visible thumbnail pop-in on modern
  devices.
- Add changelog notes for any TestFlight crash/performance fix.
- Re-run the smallest useful verification first, then broaden only for release
  gates.

## Verification Commands

```bash
scripts/savi-status-report.py
scripts/savi-crash-performance-check.py
scripts/savi-preflight.sh
scripts/savi-preflight.sh --release-build
```

Use full visual/device QA only when the change affects UI layout, scroll
behavior, onboarding, share extension UI, or release readiness:

```bash
CONFIGURATION=Release SCHEME=SAVI Tools/savi-production-ui-qa.sh
```

## Source Anchors

- `Docs/ProductionReadiness.md`
- `Docs/TestFlightReadiness.md`
- `Docs/Architecture/Runbooks/TestFlightOperations.md`
- `Docs/Architecture/Runbooks/StatusReports.md`
- `Docs/ChangeLog/2026-05-06.md`
- `Docs/ChangeLog/2026-05-07.md`
