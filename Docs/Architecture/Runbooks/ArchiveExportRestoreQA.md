# SAVI Archive Export And Restore QA

Use this runbook before handing a build to testers when the change touches
Profile, Backup, full archive export, compact JSON backup, file import/export,
Private Vault, sample-library clearing/restoring, app storage, or restore logic.

Run this checker after changing the runbook or before a release handoff:

```bash
scripts/savi-archive-restore-check.py
```

## First Rule

Archive export/restore is SAVI's safety rope. A build is not ready for wider
testing if users cannot visibly export a full archive, save it somewhere, and
restore it on a fresh install.

Do not ask testers to send real SAVI archives to the team. Archives can contain
private notes, files, screenshots, Private Vault items, door codes, recovery
codes, IDs, insurance cards, banking notes, and other sensitive content.

## Current Product Posture

- Full local archive export is the supported backup path for the first beta.
- iCloud backup is paused/no-op in Release until production CloudKit is verified.
- Exported full archives are ZIP-style packages with a `.zip` filename.
- Restore can read full archives and compact legacy JSON backups.
- Restore shows a preview first, then replaces the current local library only
  after explicit confirmation.
- Restore must never publish public links, enable social, or upload restored
  content.

## Minimum Device Matrix

Before TestFlight handoff:

- One modern iPhone.
- One iPhone 11 / iOS 17-class phone or simulator when archive UI or
  performance changed.
- Release `SAVI` / `com.altatecrd.savi`, not only Debug `SAVI Test`.

## Export Test Matrix

Run all rows with disposable/fake test content.

| Flow | Expected behavior |
|---|---|
| Profile > Backup > Export full archive > All folders | preparing/loading state appears, then the iOS share/file sheet opens |
| Export selected folders | selection count and item count are clear; empty selection cannot export accidentally |
| Compact JSON backup export | legacy JSON file exporter opens and save/cancel states are clear |
| Cancel export | user sees a non-scary cancel state; no partial restore/import happens |
| Save archive to Files/iCloud Drive | resulting file has a readable SAVI archive name and non-zero size |
| Export with Private Vault content | warning/copy makes clear private/locked content may be included |
| Export after clearing sample library | user saves still export; removed samples do not reappear unexpectedly |

Pass criteria:

- Export button is not a dead tap.
- Preparing state is visible for full archives.
- File/share sheet appears reliably.
- Save/cancel result is understandable.
- App remains responsive after export.
- No private archive data is emailed or sent to support automatically.

## Restore Test Matrix

Use a disposable archive made from fake content.

| Flow | Expected behavior |
|---|---|
| Restore full archive on same install | preview appears before replacement; confirmation is required |
| Restore full archive on fresh install | restored folders/items/assets appear; onboarding/sample state stays sensible |
| Restore compact JSON backup | legacy backup still previews and restores |
| Cancel restore preview | current library stays unchanged |
| Restore invalid file | clear error toast/message; app does not crash |
| Restore archive with images/PDFs/files | previews or file fallbacks still open after restore |
| Restore archive with Private Vault items | items remain private/locked according to current lock behavior |
| Restore after samples were cleared | samples do not merge in as new personal content unless user restores samples separately |

Pass criteria:

- Restore is never one tap from Files straight to destructive replacement.
- Preview explains item/folder counts and replacement behavior.
- Confirmation is required before replacing the current local library.
- Restored links remain links; restored files/assets remain accessible.
- Private Vault and locked-folder behavior remains intact.
- restore does not publish public links, enable social, or write to Supabase,
  PostHog, CloudKit, or any backend in Release.

## Privacy And Support Rules

Allowed tester report details:

- build number,
- device model,
- iOS version,
- archive type: full ZIP or compact JSON,
- rough archive size bucket such as under 10 MB, 10-100 MB, over 100 MB,
- flow step: preparing, share sheet, save to Files, preview, confirm restore,
  invalid file, cancel,
- error text or toast text if it does not include private filenames/content.

Forbidden unless the tester deliberately chooses to share:

- the archive file,
- screenshots of private files/IDs/passwords/recovery codes,
- private filenames,
- document contents,
- Private Vault contents,
- door codes,
- banking/insurance/medical details.

## Failure Triage

If export appears to do nothing:

1. Confirm the tester is on the current build using
   `Docs/Architecture/Runbooks/TestFlightOperations.md`.
2. Ask whether a preparing/loading state appeared.
3. Ask whether the iOS share/file sheet appeared behind another sheet.
4. Ask whether Mail/Files/iCloud Drive was available.
5. Ask the tester to submit TestFlight feedback immediately after reproducing,
   without attaching private archives.
6. Use `Docs/Architecture/Runbooks/CrashAndPerformanceTriage.md` if the app
   freezes, crashes, or becomes slow.

If restore fails:

1. Confirm the archive came from SAVI.
2. Confirm whether it is a full `.zip` archive or compact `.json` backup.
3. Confirm the preview appeared.
4. Confirm whether the failure happened before or after confirmation.
5. Do not request the archive unless the user makes a deliberate, privacy-aware
   choice to share a disposable test archive.

## Release Gate

Block wider TestFlight or App Store submission if:

- full archive export does not open the iOS share/file sheet,
- export has no visible preparing state on large libraries,
- fresh-install restore fails,
- restore can replace data without preview/confirmation,
- restored assets are missing or broken,
- Private Vault content becomes visible while locked,
- restore publishes or uploads anything in Release,
- invalid archive import crashes the app.

Internal-only investigation is acceptable if:

- compact JSON backup works but full ZIP needs polish,
- one cloud destination rejects the file but Files local save works,
- a very large archive is slow but shows progress and can complete,
- only Debug/SAVI Test is affected.

## Verification Commands

```bash
scripts/savi-archive-restore-check.py
scripts/savi-crash-performance-check.py
scripts/savi-preflight.sh
scripts/savi-preflight.sh --release-build
```

Use full visual/device QA when Profile backup UI, sheets, file exporter/importer
presentation, or restore previews changed:

```bash
CONFIGURATION=Release SCHEME=SAVI Tools/savi-production-ui-qa.sh
```

## Source Anchors

- `Docs/ProductionReadiness.md`
- `Docs/TestFlightReadiness.md`
- `Docs/Architecture/Runbooks/AppStoreSubmissionPacket.md`
- `Docs/Architecture/Runbooks/TestFlightOperations.md`
- `Docs/Architecture/Runbooks/CrashAndPerformanceTriage.md`
- `SAVI/Core/SaviArchive.swift`
- `SAVI/Core/SaviCore.swift`
- `SAVI/Views/Profile/ProfileAndFriends.swift`
- `SAVI/Views/Root/NativeSaviRootView.swift`
