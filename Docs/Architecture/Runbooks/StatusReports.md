# SAVI Status Reports

Use the status-report script when a new chat, future developer, or founder asks
"where are we right now?" It reads the repo instead of relying on conversation
memory.

```bash
scripts/savi-status-report.py
```

The report summarizes:

- current build numbers by target and configuration,
- bundle IDs by target and configuration,
- TestFlight readiness prose,
- Release/TestFlight social gate status,
- export-compliance plist keys,
- newest active work-log entries,
- dirty worktree counts,
- public-site/legal TODO placeholders,
- recommended verification commands.
- crash/performance triage command.
- Share extension real-device QA command.
- Archive export/restore QA command.
- App Store privacy labels command.
- App Store age-rating command.
- App Store export compliance command.

## When To Run

- At the start of a new SAVI chat.
- Before uploading a TestFlight build.
- Before assigning work to another developer.
- After another chat says it changed build, signing, TestFlight, social,
  analytics, or App Store readiness.

## Reading The Output

Warnings about public-site TODO placeholders are expected until the domain,
support email, privacy policy, and legal copy are finalized.

A dirty worktree is also expected while parallel Codex chats are active. Do not
reset or revert those files unless the owner explicitly asks.

If the current project build differs from the latest uploaded TestFlight build,
that means local code is ahead of TestFlight and needs a new archive/upload
before testers can see those changes.

For tester crash, freeze, or slow-scroll reports, run:

```bash
scripts/savi-crash-performance-check.py
```

Then follow `Docs/Architecture/Runbooks/CrashAndPerformanceTriage.md`.

For Share Sheet, metadata, or app-group import reports, run:

```bash
scripts/savi-share-extension-qa-check.py
```

Then follow `Docs/Architecture/Runbooks/ShareExtensionRealDeviceQA.md`.

For backup, archive export, or restore reports, run:

```bash
scripts/savi-archive-restore-check.py
```

Then follow `Docs/Architecture/Runbooks/ArchiveExportRestoreQA.md`.

For App Store privacy-label answers, run:

```bash
scripts/savi-appstore-privacy-labels-check.py
```

Then follow `Docs/Architecture/Runbooks/AppStorePrivacyLabels.md`.

For App Store age-rating/questionnaire answers, run:

```bash
scripts/savi-appstore-age-rating-check.py
```

Then follow `Docs/Architecture/Runbooks/AppStoreAgeRating.md`.

For App Store export-compliance answers, run:

```bash
scripts/savi-appstore-export-compliance-check.py
```

Then follow `Docs/Architecture/Runbooks/AppStoreExportCompliance.md`.
