# SAVI Active Work Log

Use this file as the shared coordination surface when multiple Codex chats are
working in `/Users/guest1/Documents/SAVI-iOS` at the same time.

## Coordination Rule

- Before editing, run `git status --short` and read this file.
- Treat this file as the fast cross-chat source of truth. Every Codex chat should check it before answering status or changing files.
- Add an entry with the files you expect to touch.
- Avoid files another active chat has claimed unless the change is unavoidable.
- Never revert unrelated changes from another chat.
- After verification, update your entry with status and test notes.
- For meaningful app changes, simulator refreshes, archives, or TestFlight uploads, also add or update the dated changelog in `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/`.
- For tiny coordination-only turns, update this work log rather than bloating the changelog.

## Active / Recent Entries

### 2026-05-09 12:00 CEST - GitHub sync for build 35 source

- Owner: current Codex chat
- Status: completed at 2026-05-09 12:01 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - full current repo state via Git
- Notes:
  - User asked to make sure GitHub is updated too after the `1.0 (35)` TestFlight upload.
  - Commit and push the current coordinated dirty worktree so GitHub has the source corresponding to the latest uploaded build.
  - Preserve all parallel-chat changes; do not reset or selectively revert unrelated work.
- Result:
  - Staged the full coordinated worktree, including build `35` metadata, architecture/backend docs, Mac companion/founder hub scaffolding, iOS/share-extension polish, public-site drafts, and preflight scripts.
  - `git diff --cached --check` passed after trimming extra EOF blank lines in new docs/scripts.
  - `scripts/savi-safety-scan.sh` passed with no likely app/admin secrets found outside docs/build/git.
  - Created Git commit for the current source state and prepared it for push to `origin/codex/savi-build17-pilot-sync`.

### 2026-05-09 11:50 CEST - Build 35 TestFlight upload

- Owner: current Codex chat
- Status: completed at 2026-05-09 11:59 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/SAVI.xcodeproj/project.pbxproj`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Info.plist`
  - `/Users/guest1/Documents/SAVI-iOS/SAVIShareExtension/Info.plist`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-09.md`
- Notes:
  - Build `1.0 (34)` was uploaded on 2026-05-08; the Home sample-clear polish and latest local docs are newer.
  - Bump the iOS app/share-extension build to `35`, run release validation, archive, and upload `1.0 (35)` to App Store Connect/TestFlight.
  - Preserve the current dirty worktree and do not revert unrelated edits from parallel chats.
- Result:
  - Bumped the iOS app/share-extension build settings to `35`.
  - Restored app and share-extension `CFBundleVersion` values to `$(CURRENT_PROJECT_VERSION)` after the first upload attempt revealed stale hardcoded `34` plist values.
  - Signed archive succeeded at `build/qa/archives/SAVI-20260509-115520-b35-fixed.xcarchive`.
  - Uploaded `SAVI 1.0 (35)` to App Store Connect/TestFlight; upload ended with `Uploaded SAVI` and `EXPORT SUCCEEDED`, now processing in App Store Connect.
- Verification:
  - `git diff --check` passed.
  - Release generic iPhoneOS no-sign build passed after the plist fix.
  - Corrected archive reports bundle version `35` for both `com.altatecrd.savi` and `com.altatecrd.savi.ShareExtension`.
  - Upload log: `/Users/guest1/Documents/SAVI-iOS/build/qa/logs/SAVI-export-upload-build35-fixed-20260509-115739.log`.

### 2026-05-09 11:01 CEST - Home sample clear action visibility

- Owner: current Codex chat
- Status: completed at 2026-05-09 11:03 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-09.md`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Views/Home/HomeScreen.swift`
- Notes:
  - Tight Home UI polish only: make the sample-library clear action more visible in light/dark and easier to understand before Recent Saves.
  - Do not change sample clear logic, seed data, signing, upload, App Store Connect, accounts, backend, or build number.
  - Work with current dirty file state; do not revert other-chat changes.
- Result:
  - Reworked the Home sample-library notice into a clearer control card with headline/body copy and a full-width red `Clear sample saves` button.
  - Made the action more legible in light and dark mode with stronger contrast, border, shadow, and a safer accessibility hint that personal saves are untouched.
  - Kept the card in its existing top-of-Home position before the widget/recent-saves area; clear logic and confirmation alert remain unchanged.
- Verification:
  - `git diff --check` passed before the build.
  - `xcodebuild -project SAVI.xcodeproj -scheme SAVI -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` passed.

### 2026-05-09 10:53 CEST - Simulator refresh for latest local UI

- Owner: current Codex chat
- Status: completed at 2026-05-09 10:55 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-09.md`
- Notes:
  - Reinstalled/launched local Debug `SAVI` on the booted `iPhone 17 Pro` simulator only.
  - No signing, upload, build-number, App Store Connect, account, backend, or source-code behavior changed.
- Result:
  - XcodeBuildMCP `build_run_sim` succeeded for scheme `SAVI`, configuration `Debug`, bundle `com.altatecrd.savi.personaldebug`, simulator `C99532A0-7EE8-4078-B821-703387BCFBD5`.
  - Captured a launch screenshot at `/var/folders/p2/b94vt2zd7kd1xd9q9fcdsj800000gp/T/screenshot_optimized_d70918aa-047e-4062-a123-d0d7806f71b5.jpg`.

### 2026-05-09 05:52 CEST - Share extension suggested-folder clarity

- Owner: current Codex chat
- Status: completed at 2026-05-09 05:54 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-09.md`
  - `/Users/guest1/Documents/SAVI-iOS/SAVIShareExtension/ShareViewController.swift`
- Notes:
  - Build 34 upload is complete; avoid signing, upload, project/build-number, App Store Connect, account, DNS, paid-service, backend, and share-save persistence changes.
  - Tight share-extension UI/UX pass only: make the selected/suggested folder summary explicit and easier to trust while preserving the existing two-column manual folder grid and tag flow.
  - Work with current dirty file state; do not revert other-chat changes.
- Result:
  - The Share Sheet folder summary now shows the actual selected/suggested folder name instead of the generic `Where to save` label.
  - Auto mode now reads as `SAVI Brain`, while suggested folders explain whether the choice came from link metadata, SAVI Brain rules, or Apple Intelligence when available.
  - The folder summary icon now reflects auto-vs-folder state, and the folder grid toggle now says `Hide` or `Change` instead of the vague `All`.
  - Manual folder selection, selected tags, save persistence, metadata enrichment, and the two-column folder grid behavior were left unchanged.
- Verification:
  - `git diff --check` passed before the build.
  - `xcodebuild -project SAVI.xcodeproj -scheme SAVI -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` passed.

### 2026-05-09 01:50 CEST - First-run share setup UX polish

- Owner: current Codex chat
- Status: completed at 2026-05-09 05:52 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-09.md`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Views/Components/AppComponents.swift`
- Notes:
  - Build 34 upload is complete; avoid signing, upload, project/build-number, App Store Connect, account, DNS, and paid-service changes.
  - Tight UI/UX pass only: make onboarding and Share Sheet setup clearer, more emotional, and more action-oriented without changing share-extension save logic or assets.
  - Work with current dirty file state; do not revert other-chat changes.
- Result:
  - Rewrote the first-run onboarding copy around the strongest SAVI promise: scattered links, screenshots, PDFs, and Airbnb Wi-Fi codes becoming calm and findable in one place.
  - Renamed the smart-sorting onboarding beat to `SAVI Brain` with clearer title/folder/tag suggestion language.
  - Made Share Sheet setup feel like the essential one-minute setup: stronger hero copy, clearer practice-save instructions, clearer pinned-SAVI goal copy, and a more direct reminder CTA.
  - Kept the change scoped to UI text/layout in `AppComponents.swift`; no share-extension logic, assets, signing, upload, account, or backend behavior changed.
- Verification:
  - `git diff --check` passed before the build.
  - `xcodebuild -project SAVI.xcodeproj -scheme SAVI -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` passed.

### 2026-05-09 01:36 CEST - App Store export compliance packet

- Owner: current Codex chat
- Status: completed at 2026-05-09 01:47 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-09.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/AppStoreExportCompliance.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/AppStoreSubmissionPacket.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/AppStoreConnectMetadata.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/AppStoreComplianceMatrix.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/PreflightAutomation.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/ReleaseGovernance.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/StatusReports.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/CTOHandoffIndex.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/README.md`
  - `/Users/guest1/Documents/SAVI-iOS/scripts/`
- Notes:
  - Build 34 upload is complete; avoid app code, signing, upload, App Store Connect, account, DNS, and paid-service changes.
  - Add an App Store export-compliance packet and checker for the current private-save-first build: plist keys set to `ITSAppUsesNonExemptEncryption = NO`, Apple/system encryption only, no bundled custom/proprietary crypto, founder/legal final answer still required, and re-review triggers for new SDKs/backends/crypto.
  - Docs/scripts only.
- Result:
  - Added `Docs/Architecture/Runbooks/AppStoreExportCompliance.md` with Apple source anchors, current app/share-extension plist posture, current code posture, decision guide, founder/legal final-answer warning, and future re-review triggers for crypto SDKs, backend SDKs, encrypted sync, secure messaging, custom archives, and distributed Mac/admin tools.
  - Added `scripts/savi-appstore-export-compliance-check.py` to validate both Info.plist export keys, absence of export-compliance code while the key is false, and absence of known custom/non-Apple crypto patterns in Swift sources.
  - Wired the checker into `scripts/savi-preflight.sh` and updated App Store submission, metadata, compliance, production/TestFlight readiness, release governance, preflight, status reports, CTO handoff, architecture README, safety scan, readiness/metadata checkers, status-report recommendations, and changelog.
- Verification:
  - `scripts/savi-appstore-export-compliance-check.py` passed.
  - `scripts/savi-appstore-metadata-check.py` passed.
  - `scripts/savi-appstore-readiness-check.py` passed.
  - `scripts/savi-docs-link-check.py` passed.
  - `git diff --check` passed.
  - `scripts/savi-preflight.sh` passed.

### 2026-05-09 01:25 CEST - App Store age rating answer packet

- Owner: current Codex chat
- Status: completed at 2026-05-09 01:34 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-09.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/AppStoreAgeRating.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/AppStoreConnectMetadata.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/AppStoreComplianceMatrix.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/AppStoreSubmissionPacket.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/PreflightAutomation.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/StatusReports.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/CTOHandoffIndex.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/README.md`
  - `/Users/guest1/Documents/SAVI-iOS/scripts/`
- Notes:
  - Build 34 upload is complete; avoid app code, signing, upload, App Store Connect, account, DNS, and paid-service changes.
  - Add an App Store age-rating/content questionnaire packet and checker for the current private-save-first build: no gambling, no contests, no unrestricted browser, no live social/UGC, no DMs/comments, removable sample content, neutral health research examples, and future re-rating triggers.
  - Docs/scripts only.
- Result:
  - Added `Docs/Architecture/Runbooks/AppStoreAgeRating.md` with the current private-save-first age-rating posture, Apple source anchors, recommended answer posture, App Review explanation, and future re-rating triggers for social/UGC, browser-like features, health/medical claims, mature sample content, Kids category, and monetization.
  - Added `scripts/savi-appstore-age-rating-check.py` and wired it into `scripts/savi-preflight.sh`.
  - Updated App Store Connect metadata, App Store submission packet, compliance matrix, release governance, preflight docs, status reports, CTO handoff, architecture README, safety scan, metadata/readiness checkers, status-report command recommendations, and changelog.
- Verification:
  - `scripts/savi-appstore-age-rating-check.py` passed.
  - `scripts/savi-appstore-metadata-check.py` passed.
  - `scripts/savi-appstore-readiness-check.py` passed.
  - `scripts/savi-docs-link-check.py` passed.
  - `git diff --check` passed.
  - `scripts/savi-preflight.sh` passed.

### 2026-05-09 01:15 CEST - Archive export and restore QA guardrail

- Owner: current Codex chat
- Status: completed at 2026-05-09 01:24 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-09.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ProductionReadiness.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/TestFlightReadiness.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/ArchiveExportRestoreQA.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/AppStoreSubmissionPacket.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/PreflightAutomation.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/ReleaseGovernance.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/StatusReports.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/CTOHandoffIndex.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/README.md`
  - `/Users/guest1/Documents/SAVI-iOS/scripts/`
- Notes:
  - Build 34 upload is complete; avoid app code, signing, upload, App Store Connect, account, DNS, and paid-service changes.
  - Add an archive export/restore QA runbook/checker for Profile backup, preparing/loading state, iOS file/share exporter, full ZIP archive, compact JSON legacy backup, fresh-install restore, private/vault warning, sample-library separation, and no social publishing on restore.
  - Docs/scripts only.
- Result:
  - Added `Docs/Architecture/Runbooks/ArchiveExportRestoreQA.md` for Profile backup, full ZIP archive export, compact JSON backup, cancel states, invalid file handling, fresh-install restore, Private Vault behavior, sample-library separation, and the rule that restore never publishes or uploads anything in Release.
  - Added `scripts/savi-archive-restore-check.py` and wired it into `scripts/savi-preflight.sh`.
  - Updated production readiness, TestFlight readiness, App Store submission, release governance, status reports, CTO handoff, architecture README, safety scan, status-report command recommendations, and changelog.
- Verification:
  - `scripts/savi-archive-restore-check.py` passed.
  - `scripts/savi-docs-link-check.py` passed.
  - `git diff --check` passed.
  - `scripts/savi-preflight.sh` passed.

### 2026-05-09 01:05 CEST - App Store privacy labels answer packet

- Owner: current Codex chat
- Status: completed at 2026-05-09 01:14 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-09.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/AppStorePrivacyWorksheet.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/PrivacyDataInventory.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/AppStoreComplianceMatrix.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/AppStorePrivacyLabels.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/AppStoreSubmissionPacket.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/PreflightAutomation.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/StatusReports.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/CTOHandoffIndex.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/README.md`
  - `/Users/guest1/Documents/SAVI-iOS/scripts/`
- Notes:
  - Build 34 upload is complete; avoid app code, signing, upload, App Store Connect, account, DNS, and paid-service changes.
  - Add a copy-paste App Store privacy labels runbook/checker for the current private-save-first build: local-only content, user-initiated feedback, Apple/TestFlight diagnostics, no live Supabase/PostHog/APNs/social.
  - Docs/scripts only.
- Result:
  - Added `Docs/Architecture/Runbooks/AppStorePrivacyLabels.md` with the current private-save-first privacy-label draft, conservative support-disclosure alternative, remote metadata notes, and future Supabase/PostHog/APNs/social update triggers.
  - Added `scripts/savi-appstore-privacy-labels-check.py` and wired it into `scripts/savi-preflight.sh`.
  - Updated the App Store privacy worksheet, privacy data inventory, compliance matrix, App Store submission packet, preflight docs, status reports, CTO handoff, architecture README, safety scan, status-report command recommendations, and changelog.
- Verification:
  - `scripts/savi-appstore-privacy-labels-check.py` passed.
  - `scripts/savi-privacy-inventory-check.py` passed.
  - `scripts/savi-docs-link-check.py` passed.
  - `git diff --check` passed.
  - `scripts/savi-preflight.sh` passed.

### 2026-05-09 00:48 CEST - Crash and performance triage guardrail

- Owner: current Codex chat
- Status: completed at 2026-05-09 00:55 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-09.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ProductionReadiness.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/CrashAndPerformanceTriage.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/TestFlightOperations.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/PreflightAutomation.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/StatusReports.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/CTOHandoffIndex.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/README.md`
  - `/Users/guest1/Documents/SAVI-iOS/scripts/`
- Notes:
  - Build 34 upload is complete; avoid app code, signing, upload, App Store Connect, and account changes.
  - Add a crash/performance triage runbook/checker for iPhone 11/iOS 17-style launch crashes, slow scrolling, freezes, TestFlight feedback intake, and privacy-safe diagnostics.
  - Docs/scripts only.
- Result:
  - Added `Docs/Architecture/Runbooks/CrashAndPerformanceTriage.md` for iPhone 11/iOS 17-style launch crashes, freezes, slow Home/Search/Explore scrolling, thumbnail jank, share extension failures, TestFlight feedback intake, privacy-safe diagnostic notes, and fix discipline.
  - Added `scripts/savi-crash-performance-check.py` and wired it into `scripts/savi-preflight.sh`.
  - Updated production readiness, TestFlight operations, status reports, preflight docs, CTO handoff, architecture README, safety scan, status-report command recommendations, and changelog.
- Verification:
  - `scripts/savi-crash-performance-check.py` passed.
  - `scripts/savi-testflight-ops-check.py` passed.
  - `scripts/savi-docs-link-check.py` passed.
  - `git diff --check` passed.
  - `scripts/savi-preflight.sh` passed.

### 2026-05-09 00:56 CEST - Share extension real-device QA guardrail

- Owner: current Codex chat
- Status: completed at 2026-05-09 01:04 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-09.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ProductionReadiness.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/TestFlightReadiness.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/ShareExtensionRealDeviceQA.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/AppStoreSubmissionPacket.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/PreflightAutomation.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/ReleaseGovernance.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/StatusReports.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/CTOHandoffIndex.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/README.md`
  - `/Users/guest1/Documents/SAVI-iOS/scripts/`
- Notes:
  - Build 34 upload is complete; avoid app code, signing, upload, App Store Connect, account, DNS, and paid-service changes.
  - Add a real-device Share Extension QA runbook/checker covering Safari, YouTube, TikTok/Instagram/X, Photos screenshots/images, Files PDFs/generic files, plain text, metadata fallbacks, app-group import, privacy-safe tester notes, and iPhone 11/modern spot checks.
  - Docs/scripts only.
- Result:
  - Added `Docs/Architecture/Runbooks/ShareExtensionRealDeviceQA.md` for the real-device Share Sheet save matrix, metadata fallback, app-group import checks, privacy-safe tester notes, and Release/iPhone 11-class device expectations.
  - Added `scripts/savi-share-extension-qa-check.py` and wired it into `scripts/savi-preflight.sh`.
  - Updated production readiness, TestFlight readiness, App Store submission, release governance, status reports, CTO handoff, architecture README, safety scan, status-report command recommendations, and changelog.
- Verification:
  - `scripts/savi-share-extension-qa-check.py` passed.
  - `scripts/savi-docs-link-check.py` passed.
  - `git diff --check` passed.
  - `scripts/savi-preflight.sh` passed.

### 2026-05-09 00:39 CEST - TestFlight operations guardrail

- Owner: current Codex chat
- Status: completed at 2026-05-09 00:45 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-09.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/TestFlightReadiness.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/TestFlightOperations.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/AppStoreSubmissionPacket.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/PreflightAutomation.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/CTOHandoffIndex.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/README.md`
  - `/Users/guest1/Documents/SAVI-iOS/scripts/`
- Notes:
  - Build 34 upload is complete; avoid app code, signing, upload, App Store Connect changes, and account invites.
  - Add a TestFlight operations runbook/checker for internal tester emails, build assignment, old-build troubleshooting, and current build drift.
  - Docs/scripts only.
- Result:
  - Added `Docs/Architecture/Runbooks/TestFlightOperations.md` with current build `1.0 (34)`, internal group `SAVI Internal`, tester emails to verify, build assignment steps, tester install instructions, old-build troubleshooting, and official Apple TestFlight source anchors.
  - Added `scripts/savi-testflight-ops-check.py` and wired it into `scripts/savi-preflight.sh`.
  - Updated TestFlight readiness, App Store submission packet, preflight docs, CTO handoff, architecture README, safety scan, status report recommendations, and changelog.
- Verification:
  - `scripts/savi-testflight-ops-check.py` passed.
  - `scripts/savi-appstore-metadata-check.py` passed.
  - `scripts/savi-docs-link-check.py` passed.
  - `git diff --check` passed.
  - `scripts/savi-preflight.sh` passed.

### 2026-05-09 00:29 CEST - App Store metadata packet guardrail

- Owner: current Codex chat
- Status: completed at 2026-05-09 00:36 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-09.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/TestFlightReadiness.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/AppStoreConnectMetadata.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/AppStoreSubmissionPacket.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/CTOHandoffIndex.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/README.md`
  - `/Users/guest1/Documents/SAVI-iOS/scripts/`
- Notes:
  - Build 34 upload is complete; avoid app code, signing, upload, App Store Connect, and paid/account work.
  - Add a concrete App Store Connect metadata packet/checker and fix stale TestFlight readiness references to older build 27.
  - Docs/scripts only.
- Result:
  - Added `Docs/Architecture/Runbooks/AppStoreConnectMetadata.md` with copy-paste App Store Connect fields, product page copy, keyword string, TestFlight beta description, What to Test, App Review notes, screenshot storyboard, age-rating notes, and final human replacements.
  - Added `scripts/savi-appstore-metadata-check.py` and wired it into `scripts/savi-preflight.sh`.
  - Fixed stale `Docs/TestFlightReadiness.md` build `27` references and renamed the old "Build 4" hardening heading.
  - Updated App Store submission packet, CTO handoff, architecture README, preflight docs, safety scan, and changelog.
- Verification:
  - `scripts/savi-appstore-metadata-check.py` passed.
  - `scripts/savi-appstore-readiness-check.py` passed.
  - `scripts/savi-docs-link-check.py` passed.
  - `git diff --check` passed.
  - `scripts/savi-preflight.sh` passed.

### 2026-05-09 00:18 CEST - Public-site static export

- Owner: current Codex chat
- Status: completed at 2026-05-09 00:25 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-09.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/PublicSite/`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/SetupChecklist.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/PreflightAutomation.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/AppStoreSubmissionPacket.md`
  - `/Users/guest1/Documents/SAVI-iOS/scripts/`
- Notes:
  - Build 34 upload is complete; avoid app code, signing, upload, DNS, App Store Connect, and paid account changes.
  - Add a dependency-free static-site builder/checker for the public legal/support pages so the future domain step is just publishing generated files.
  - Generated output should stay under ignored `build/`.
- Result:
  - Added `scripts/savi-public-site-build.py`, which exports the public-site Markdown pages to static HTML under `build/public-site/`.
  - Added `scripts/savi-public-site-check.py` and wired it into `scripts/savi-preflight.sh`.
  - Added `Docs/PublicSite/StaticSitePublishing.md` with generated pages, deployment options, URL shapes, and do-not-publish secret/admin rules.
  - Updated public-site README, setup checklist, preflight docs, App Store submission packet, and today's changelog.
- Verification:
  - `scripts/savi-public-site-build.py` generated `build/public-site/index.html`, `privacy.html`, `terms.html`, `support.html`, `data-deletion.html`, and `community-guidelines.html`.
  - `scripts/savi-public-site-check.py` passed.
  - `scripts/savi-appstore-readiness-check.py` passed with no warnings.
  - `scripts/savi-docs-link-check.py` passed.
  - `git diff --check` passed.
  - `scripts/savi-preflight.sh` passed.

### 2026-05-09 00:12 CEST - Public-site draft cleanup

- Owner: current Codex chat
- Status: completed at 2026-05-09 00:16 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-09.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/PublicSite/privacy.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/PublicSite/terms.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/PublicSite/support.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/PublicSite/data-deletion.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/PublicSite/README.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/PreflightAutomation.md`
- Notes:
  - Build 34 upload is complete; avoid signing/upload and app code.
  - Remove public-site TODO placeholders using the current documented beta support email, while keeping legal/domain approval as a final human step.
  - Docs only; no App Store Connect, DNS, or paid account changes.
- Result:
  - Replaced remaining public-site TODO placeholders in privacy, terms, support, and data-deletion drafts with `1080solutionsA@gmail.com`.
  - Updated public-site README to call these publication-ready drafts that still need final domain/company/legal review.
  - Updated preflight docs so public-site TODO warnings are no longer expected for normal release prep.
  - Added `Docs/ChangeLog/2026-05-09.md`.
- Verification:
  - `rg -n "TODO" Docs/PublicSite` returned no matches.
  - `scripts/savi-appstore-readiness-check.py` passed with no warnings.
  - `scripts/savi-docs-link-check.py` passed.
  - `git diff --check` passed.
  - `scripts/savi-preflight.sh` passed and reports no public-site TODO placeholders.

### 2026-05-09 00:04 CEST - Sample content safety guardrail

- Owner: current Codex chat
- Status: completed at 2026-05-09 00:09 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-08.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/SampleContentReview.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/AppStoreComplianceMatrix.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/AppStoreSubmissionPacket.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/CTOHandoffIndex.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/README.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Design/SampleLibrarySources.md`
  - `/Users/guest1/Documents/SAVI-iOS/scripts/`
- Notes:
  - Build 34 upload is complete; avoid signing/upload and unrelated app UI/code.
  - Add a sample-library safety review/checker so health hooks, meme/video links, fake private documents, and rabbit-hole examples stay App Store-friendly.
  - Docs/scripts only; do not change sample order, thumbnails, app UI, or project build settings in this pass.
- Result:
  - Added `Docs/Architecture/SampleContentReview.md` as the living sample-library App Store/IP/health-safety review.
  - Added `scripts/savi-sample-content-check.py` and wired it into `scripts/savi-preflight.sh`.
  - Updated compliance, App Store submission, CTO handoff, architecture README, sample-source notes, safety scan, and changelog docs.
  - The checker validates health disclaimers, NCI counterbalance, remote YouTube metadata posture, fake private-document wording, source documentation, and banned medical-claim wording.
- Verification:
  - `scripts/savi-sample-content-check.py` passed.
  - `scripts/savi-appstore-readiness-check.py` passed with only expected public-site TODO warnings.
  - `scripts/savi-docs-link-check.py` passed.
  - `git diff --check` passed.
  - `scripts/savi-preflight.sh` passed with only expected public-site TODO warnings.

### 2026-05-08 23:56 CEST - Third-party SDK inventory guardrail

- Owner: current Codex chat
- Status: completed at 2026-05-09 00:00 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-08.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/`
  - `/Users/guest1/Documents/SAVI-iOS/scripts/`
- Notes:
  - Build 34 upload is complete; avoid signing/upload and unrelated app UI/code.
  - Current source has no SwiftPM/CocoaPods/Carthage packages and uses Apple/system frameworks only.
  - Add a third-party SDK inventory/checker so adding Supabase/PostHog/Sentry/etc. later triggers privacy/security review.
- Result:
  - Added `Docs/Architecture/ThirdPartySDKInventory.md` documenting the current no-third-party-SDK state and future SDK review gate.
  - Added `scripts/savi-sdk-inventory-check.py` and wired it into `scripts/savi-preflight.sh`.
  - Updated compliance, privacy inventory, submission, release, preflight, CTO, architecture, safety scan, roadmap, and changelog docs.
  - Current scan confirms no SwiftPM/CocoaPods/Carthage package files, no checked-in vendor frameworks, no Swift package references, and Apple/system Swift imports only.
- Verification:
  - `scripts/savi-sdk-inventory-check.py` passed.
  - `scripts/savi-privacy-inventory-check.py` passed.
  - `scripts/savi-docs-link-check.py` passed.
  - `git diff --check` passed.
  - `scripts/savi-preflight.sh` passed with only expected public-site TODO warnings.

### 2026-05-08 23:53 CEST - Privacy manifest required-reason API audit

- Owner: current Codex chat
- Status: completed at 2026-05-08 23:58 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-08.md`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/PrivacyInfo.xcprivacy`
  - `/Users/guest1/Documents/SAVI-iOS/SAVIShareExtension/PrivacyInfo.xcprivacy`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/`
  - `/Users/guest1/Documents/SAVI-iOS/scripts/`
- Notes:
  - Build 34 upload is complete; avoid signing/upload and unrelated app UI/code.
  - Current source uses `UserDefaults`, while the app manifest only declares file timestamps.
  - Add target-aware privacy manifest audit/checker using Apple required-reason API guidance.
- Result:
  - Updated `SAVI/PrivacyInfo.xcprivacy` to declare `NSPrivacyAccessedAPICategoryUserDefaults` with reason `CA92.1`, matching current main-app `UserDefaults` use.
  - Kept `NSPrivacyAccessedAPICategoryFileTimestamp` with reason `C617.1` in both app and share extension manifests.
  - Added `Docs/Architecture/PrivacyManifestAudit.md`.
  - Added `scripts/savi-privacy-manifest-check.py` and wired it into `scripts/savi-preflight.sh`.
  - Updated compliance, submission, preflight, CTO, architecture, worksheet, safety scan, roadmap, and changelog docs.
- Verification:
  - `scripts/savi-privacy-manifest-check.py` passed.
  - `plutil -lint SAVI/PrivacyInfo.xcprivacy SAVIShareExtension/PrivacyInfo.xcprivacy` passed.
  - `scripts/savi-appstore-readiness-check.py` passed with only expected public-site TODO warnings.
  - `scripts/savi-docs-link-check.py` passed.
  - `git diff --check` passed.
  - `scripts/savi-preflight.sh` passed with only expected public-site TODO warnings.

### 2026-05-08 23:49 CEST - Privacy data inventory guardrail

- Owner: current Codex chat
- Status: completed at 2026-05-08 23:53 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-08.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Backend/`
  - `/Users/guest1/Documents/SAVI-iOS/scripts/`
- Notes:
  - Build 34 upload is complete; keep avoiding app UI/code, signing, upload, and credentials.
  - Add a living privacy-label/data inventory tied to Apple App Store privacy disclosure expectations.
  - Docs/scripts only; no live analytics, Supabase, PostHog, APNs, or App Store Connect changes.
- Result:
  - Added `Docs/Architecture/PrivacyDataInventory.md` as the living source for App Store privacy-label preparation across current local-only behavior and future Supabase/PostHog/APNs/social/sync data flows.
  - Added `scripts/savi-privacy-inventory-check.py` and wired it into `scripts/savi-preflight.sh`.
  - Updated compliance, submission packet, release governance, preflight, CTO, architecture, backend, safety scan, and roadmap docs.
  - Used official Apple app privacy docs as source anchors.
- Verification:
  - `scripts/savi-privacy-inventory-check.py` passed.
  - `scripts/savi-appstore-readiness-check.py` passed with only expected public-site TODO warnings.
  - `scripts/savi-docs-link-check.py` passed.
  - `git diff --check` passed.
  - `scripts/savi-preflight.sh` passed with only expected public-site TODO warnings.

### 2026-05-08 23:46 CEST - Notification/APNs readiness guardrail

- Owner: current Codex chat
- Status: completed at 2026-05-08 23:49 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-08.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Backend/`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/`
  - `/Users/guest1/Documents/SAVI-iOS/scripts/`
- Notes:
  - Build 34 upload is complete; keep avoiding app UI/code, signing, upload, and credentials.
  - Add a concrete future notification/APNs privacy contract before any push work starts.
  - Docs/scripts/OpenAPI contract only; no APNs entitlements, no SDK calls, no device-token collection.
- Result:
  - Added `Docs/Backend/NotificationRunbook.md` with future permission timing, APNs backend boundary, allowed/forbidden content, device-token storage rules, settings requirements, analytics limits, and push launch checklist.
  - Added future notification routes/schemas to `Docs/Backend/OpenAPI/savi-social-v1.openapi.yaml` for device-token registration/deletion and notification settings.
  - Added `scripts/savi-notification-readiness-check.py` and wired it into `scripts/savi-preflight.sh`.
  - Updated backend, social UX, compliance, setup, release, CTO, safety scan, and preflight docs.
- Verification:
  - `scripts/savi-notification-readiness-check.py` passed.
  - `scripts/savi-openapi-contract-check.py` passed.
  - `scripts/savi-docs-link-check.py` passed.
  - `git diff --check` passed.
  - `scripts/savi-preflight.sh` passed with only expected public-site TODO warnings.

### 2026-05-08 23:43 CEST - Account deletion readiness guardrail

- Owner: current Codex chat
- Status: completed at 2026-05-08 23:46 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-08.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Backend/`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/PublicSite/`
  - `/Users/guest1/Documents/SAVI-iOS/scripts/`
- Notes:
  - Build 34 upload is complete; continue avoiding app UI/code, signing, upload, and credentials.
  - Add a concrete account deletion runbook and checker so future accounts/social work satisfies Apple account-deletion expectations.
  - Docs/scripts only; no live Supabase, auth, App Store Connect, or secrets.
- Result:
  - Added `Docs/Backend/AccountDeletionRunbook.md` with future `DELETE /me/account`, Sign in with Apple revocation, Supabase cascade, local-library boundary, and test checklist details.
  - Added `scripts/savi-account-deletion-check.py` and wired it into `scripts/savi-preflight.sh`.
  - Updated compliance, API, social, security, setup, release, CTO, backend, public data-deletion, and preflight docs.
- Verification:
  - `scripts/savi-account-deletion-check.py` passed.
  - `scripts/savi-openapi-contract-check.py` passed.
  - `scripts/savi-docs-link-check.py` passed.
  - `git diff --check` passed.
  - `scripts/savi-preflight.sh` passed with only expected public-site TODO warnings.

### 2026-05-08 23:39 CEST - Moderation workflow and admin API guardrail

- Owner: current Codex chat
- Status: completed at 2026-05-08 23:43 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-08.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Backend/`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/`
  - `/Users/guest1/Documents/SAVI-iOS/scripts/`
- Notes:
  - Build 34 upload is complete; still avoid app UI/code, signing, upload, and credentials.
  - Add a concrete protected-admin moderation workflow/API contract for future social launch readiness.
  - Keep admin/service-role concepts out of consumer app targets; docs/scripts only.
- Result:
  - Added `Docs/Backend/AdminModerationWorkflow.md` with protected queue, report states, public-link hide/unhide, audit-log, and App Store social gate requirements.
  - Added `Docs/Backend/OpenAPI/savi-admin-v1.openapi.yaml` as an internal-only Admin Moderation API draft.
  - Added `scripts/savi-moderation-readiness-check.py` and wired it into `scripts/savi-preflight.sh`.
  - Updated backend, desktop, CTO handoff, safety scan, and preflight docs.
- Verification:
  - `scripts/savi-moderation-readiness-check.py` passed.
  - `scripts/savi-openapi-contract-check.py` passed.
  - `scripts/savi-docs-link-check.py` passed.
  - `git diff --check` passed.
  - `scripts/savi-preflight.sh` passed with only expected public-site TODO warnings.

### 2026-05-08 23:29 CEST - Social OpenAPI contract guardrail

- Owner: current Codex chat
- Status: completed at 2026-05-08 23:30 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-08.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Backend/OpenAPI/savi-social-v1.openapi.yaml`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/APIContract.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/PreflightAutomation.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/CTOHandoffIndex.md`
  - `/Users/guest1/Documents/SAVI-iOS/scripts/`
- Notes:
  - Build 34 TestFlight upload is active in another chat; avoid project/build/signing/upload/app UI files.
  - Add account deletion to the Social V1 API contract and add a dependency-free OpenAPI contract checker.
  - Documentation/scripts only; no server credentials or app code.
- Result:
  - Added `DELETE /me/account` to `Docs/Backend/OpenAPI/savi-social-v1.openapi.yaml`.
  - Added OpenAPI schemas for profiles, profile updates, public-link publishing, and reports.
  - Updated `Docs/Architecture/APIContract.md` with the account-deletion cascade/revocation requirement.
  - Added `scripts/savi-openapi-contract-check.py` and wired it into `scripts/savi-preflight.sh`.
  - Updated preflight/CTO docs and today's changelog.
- Verification:
  - `scripts/savi-openapi-contract-check.py` passed.
  - `scripts/savi-backend-readiness-check.py` passed.
  - `git diff --check` passed.
  - `scripts/savi-preflight.sh` passed.

### 2026-05-08 23:26 CEST - Build 34 TestFlight upload

- Owner: current Codex chat
- Status: completed at 2026-05-08 23:32 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-08.md`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI.xcodeproj/project.pbxproj`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Info.plist`
  - `/Users/guest1/Documents/SAVI-iOS/SAVIShareExtension/Info.plist`
  - `/Users/guest1/Documents/SAVI-iOS/build/qa/exportOptions-app-store-connect-b34.plist`
- Notes:
  - User asked to push to TestFlight after the Home sample-clear confirmation.
  - Upload Release `SAVI` / `com.altatecrd.savi`, not `SAVI Test`.
  - Bump iOS app and share extension from build `33` to `34` so the latest sample-clear confirmation is included and duplicate-build issues are avoided.
  - Archive path target: `/Users/guest1/Documents/SAVI-iOS/build/qa/archives/SAVI-20260508-232717-b34.xcarchive`.
  - Export/upload log target: `/Users/guest1/Documents/SAVI-iOS/build/qa/logs/SAVI-export-upload-build34-20260508-232717.log`.
- Result:
  - Bumped iOS app and share extension to `1.0 (34)`.
  - Signed Release archive succeeded:
    `/Users/guest1/Documents/SAVI-iOS/build/qa/archives/SAVI-20260508-232717-b34.xcarchive`.
  - Uploaded `SAVI 1.0 (34)` to App Store Connect/TestFlight; upload ended with `Uploaded SAVI` and `EXPORT SUCCEEDED`.
  - Build is now processing in App Store Connect.
- Verification:
  - `git diff --check` passed before archive.
  - Release archive succeeded.
  - Export/upload succeeded.

### 2026-05-08 23:25 CEST - Supabase RLS static guardrail

- Owner: current Codex chat
- Status: completed at 2026-05-08 23:27 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-08.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Backend/Supabase/social_v1_schema.sql`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Backend/Supabase/rls_test_plan.sql`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/PreflightAutomation.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/CTOHandoffIndex.md`
  - `/Users/guest1/Documents/SAVI-iOS/scripts/`
- Notes:
  - Other chat owns Home sample-clear confirmation; avoid app UI and app code edits.
  - Add a dependency-free static checker for Supabase Social V1 RLS policies.
  - Harden only docs/schema/runbooks/scripts; do not connect to Supabase or add credentials.
- Result:
  - Added `scripts/savi-supabase-rls-check.py`.
  - Wired it into `scripts/savi-preflight.sh`.
  - Hardened `Docs/Backend/Supabase/social_v1_schema.sql` with constrained report statuses and blocked-user visibility for link likes.
  - Expanded `Docs/Backend/Supabase/rls_test_plan.sql` with blocked-like visibility, invalid report status, and account deletion cascade expectations.
  - Updated preflight/CTO docs and today's changelog.
- Verification:
  - `scripts/savi-supabase-rls-check.py` passed.
  - `scripts/savi-backend-readiness-check.py` passed.
  - `git diff --check` passed.
  - `scripts/savi-preflight.sh` passed.

### 2026-05-08 23:22 CEST - Analytics contract privacy checker

- Owner: current Codex chat
- Status: completed at 2026-05-08 23:23 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-08.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Backend/AnalyticsEventCatalog.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Backend/Schemas/analytics-event.schema.json`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Backend/Fixtures/`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/PreflightAutomation.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/CTOHandoffIndex.md`
  - `/Users/guest1/Documents/SAVI-iOS/scripts/`
- Notes:
  - Other chat owns Home/Profile sample-clear confirmation; avoid app UI and app code edits.
  - Add a dependency-free analytics contract checker that compares docs/schema/fixtures against the existing app allowlist.
  - Keep `saved_item_shared_out` documented as planned until app code actually emits it.
  - Documentation/scripts/fixtures only.
- Result:
  - Added `scripts/savi-analytics-contract-check.py`.
  - Wired it into `scripts/savi-preflight.sh`.
  - Aligned analytics fixtures with app property keys: `build_number`, `save_source_group`, and `is_public`.
  - Removed `saved_item_shared_out` from the current backend schema/fixture validator so it remains planned-only until implementation.
  - Updated preflight/CTO docs and today's changelog.
- Verification:
  - `scripts/savi-analytics-contract-check.py` passed.
  - `scripts/savi-contract-fixtures-check.py` passed.
  - `git diff --check` passed.
  - `scripts/savi-preflight.sh` passed.

### 2026-05-08 23:19 CEST - Documentation link integrity checker

- Owner: current Codex chat
- Status: completed at 2026-05-08 23:20 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-08.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/PreflightAutomation.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/CTOHandoffIndex.md`
  - `/Users/guest1/Documents/SAVI-iOS/scripts/`
- Notes:
  - Other chat currently owns Home/Profile sample-clear revert and upload work is paused; avoid app UI/code and signing/upload.
  - Add a dependency-free docs link/path checker and wire it into quick preflight so architecture/runbook/handoff links stay valid.
  - Documentation/scripts only.
- Result:
  - Added `scripts/savi-docs-link-check.py`.
  - Wired the docs link checker into `scripts/savi-preflight.sh`.
  - Linked the checker from `Docs/Architecture/Runbooks/PreflightAutomation.md` and `Docs/Architecture/CTOHandoffIndex.md`.
  - Added a changelog note under `Documentation Link Integrity`.
- Verification:
  - `scripts/savi-docs-link-check.py` passed, checking 55 live docs and 231 internal links/paths.
  - `git diff --check` passed.
  - `scripts/savi-preflight.sh` passed.

### 2026-05-08 23:16 CEST - Target-aware status report cleanup

- Owner: current Codex chat
- Status: completed at 2026-05-08 23:17 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-08.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/StatusReports.md`
  - `/Users/guest1/Documents/SAVI-iOS/scripts/savi-status-report.py`
- Notes:
  - Other chat currently owns Build 33 screenshot QA/TestFlight upload; do not touch upload, signing, screenshots, or app UI.
  - Improve the status report so iOS app/share-extension build `33` and Mac build `1` are clearly separated by target/configuration.
  - Documentation/scripts only.
- Result:
  - `scripts/savi-status-report.py` now lists builds by target and configuration:
    `SAVI Debug`, `SAVI Release`, `SAVIShareExtension Debug`, `SAVIShareExtension Release`, `SAVI Mac Debug`, and `SAVI Mac Release`.
  - Updated the status-report runbook and changelog to describe target-aware build reporting.
- Verification:
  - `scripts/savi-status-report.py` passed and clearly separates iOS/share-extension build `33` from Mac build `1`.
  - `git diff --check` passed.
  - `scripts/savi-preflight.sh` passed.

### 2026-05-08 23:14 CEST - Build 33 screenshot QA and TestFlight upload

- Owner: current Codex chat
- Status: paused by user before archive/upload
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-08.md`
- Notes:
  - User asked to double-check screenshots, improve only if obvious, then upload to TestFlight.
  - Current local app/share-extension build is `1.0 (33)`; latest documented uploaded TestFlight build is `1.0 (27)`.
  - Use Release `SAVI` / `com.altatecrd.savi` as the upload target, not `SAVI Test`.
  - Avoid broad UI refactors unless screenshot QA shows a clear blocker.
  - Screenshot QA on iPhone 17 Pro Debug showed Home readable and no obvious clipping.
  - Preflight passed with expected public-site TODO warnings.
  - User interrupted before archive/upload and asked to revert the sample-clear guidance change.

### 2026-05-08 23:18 CEST - Revert sample clear guidance

- Owner: current Codex chat
- Status: completed at 2026-05-08 23:21 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Views/Home/HomeScreen.swift`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Views/Profile/ProfileAndFriends.swift`
- Notes:
  - User rejected the highlighted sample-clear guidance.
  - Revert only that recent Home/Profile sample-clear UI copy/behavior.
  - Restore compact Home notice with direct `Clear` action and previous Profile `Library` copy/button.
- Result:
  - Restored the compact Home sample notice and Profile `Library` copy/button.
  - Upload remained paused; no TestFlight archive/upload happened after the user interruption.
- Verification:
  - `git diff --check` passed.
  - Debug generic iOS Simulator build passed with `CODE_SIGNING_ALLOWED=NO`.

### 2026-05-08 23:21 CEST - Home sample clear confirmation

- Owner: current Codex chat
- Status: completed at 2026-05-08 23:25 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Views/Home/HomeScreen.swift`
- Notes:
  - User wants the Home banner to show a simple pop-up explaining that sample saves can be cleared when ready.
  - Keep the banner compact and avoid another large sample guidance card.
  - Add a confirmation before clearing examples; clarify personal saves stay untouched.
- Result:
  - Home sample banner still stays compact.
  - Tapping `Clear` now opens a plain confirmation alert explaining that only SAVI's sample saves are removed and anything the user added stays untouched.
- Verification:
  - `git diff --check` passed.
  - Debug generic iOS Simulator build passed with `CODE_SIGNING_ALLOWED=NO`.

### 2026-05-08 23:08 CEST - CPR card preview route cleanup

- Owner: current Codex chat
- Status: completed at 2026-05-08 23:08 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Services/LegacyAndUtilities.swift`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Views/Save/SaveAndEditSheets.swift`
- Notes:
  - The CPR sample uses a Red Cross URL that redirects and item hero taps currently use the system `openURL` path.
  - Keep URL item hero taps inside SAVI's preview sheet; leave explicit `Open` button for Safari.
  - Use the canonical Red Cross CPR URL to avoid the simulator redirect hop.
- Result:
  - Updated the CPR sample to the canonical Red Cross URL.
  - Changed item-detail hero taps for URL saves to open SAVI's in-app web preview sheet instead of jumping straight to the system `openURL` path.
  - The explicit `Open` button still opens the URL externally.
- Verification:
  - `git diff --check` passed.
  - Debug generic iOS Simulator build passed with `CODE_SIGNING_ALLOWED=NO`.

### 2026-05-08 23:04 CEST - App Store submission packet and checker

- Owner: current Codex chat
- Status: completed at 2026-05-08 23:08 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-08.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/README.md`
  - `/Users/guest1/Documents/SAVI-iOS/scripts/`
- Notes:
  - Other chat currently owns Home/Profile sample cleanup; avoid app UI files.
  - Add an account-free App Store/TestFlight submission packet and readiness checker.
  - Documentation/scripts only; no signing, upload, App Store Connect, or UI changes.
  - Added `Docs/Architecture/Runbooks/AppStoreSubmissionPacket.md`.
  - Added `scripts/savi-appstore-readiness-check.py` and wired it into `scripts/savi-preflight.sh`.
  - Clarified `Docs/TestFlightReadiness.md` so current local build `33` is separate from latest uploaded TestFlight build `1.0 (27)`.
  - Verification: App Store readiness check passes, `git diff --check` passes, and `scripts/savi-preflight.sh` passes.
  - Remaining warning is expected until founder/domain/legal setup: public-site templates still have TODO support/privacy placeholders.

### 2026-05-08 23:11 CEST - Cross-chat status report tool

- Owner: current Codex chat
- Status: completed at 2026-05-08 23:13 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-08.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/README.md`
  - `/Users/guest1/Documents/SAVI-iOS/scripts/`
- Notes:
  - Other chats are touching app UI and sample assets; avoid app UI/code files.
  - Add a no-account status-report script that summarizes current build IDs, TestFlight docs, work-log entries, dirty worktree counts, public-site blockers, and preflight commands.
  - Documentation/scripts only; no signing, upload, App Store Connect, or UI changes.
- Result:
  - Added `scripts/savi-status-report.py`.
  - Added `Docs/Architecture/Runbooks/StatusReports.md`.
  - Linked the status report from the architecture README and CTO handoff index.
  - Added the App Store submission packet and status-report runbook to the safety scan's documentation front-door checks.
- Verification:
  - `scripts/savi-status-report.py` passed and reported local build `33` versus latest uploaded TestFlight build `1.0 (27)`.
  - `git diff --check` passed.
  - `scripts/savi-preflight.sh` passed.

### 2026-05-08 23:01 CEST - Backend contract fixtures and validator

- Owner: current Codex chat
- Status: completed at 2026-05-08 23:03 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-08.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Backend/Fixtures/`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Backend/README.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/PreflightAutomation.md`
  - `/Users/guest1/Documents/SAVI-iOS/scripts/`
- Notes:
  - Other chat currently owns Home/Profile sample cleanup; avoid app UI files.
  - Add contract fixture examples and a dependency-free validator for item, public link, analytics, and privacy constraints.
  - Documentation/scripts only; no app UI, backend credentials, or build settings changes.
  - Added valid/invalid backend contract fixtures for item, public link, and analytics payloads.
  - Added `scripts/savi-contract-fixtures-check.py` and wired it into `scripts/savi-preflight.sh`.
  - Verification: fixture validator passes, `git diff --check` passes, and `scripts/savi-preflight.sh` passes.

### 2026-05-08 23:00 CEST - Sample cleanup guidance highlight

- Owner: current Codex chat
- Status: completed at 2026-05-08 23:05 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Views/Home/HomeScreen.swift`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Views/Profile/ProfileAndFriends.swift`
- Notes:
  - Make Home clearly tell users where to clear sample saves when they are ready.
  - Keep the reassurance explicit: clearing samples does not affect personal saves.
  - Avoid adding another onboarding popup.
- Result:
  - Home sample notice now highlights that sample saves are safe to clear and points users to `Profile > Library > Clear sample saves`.
  - The Home notice action now jumps to Profile and shows a toast instead of immediately clearing anything.
  - Profile now labels the section `Library & samples`, explains that personal saves stay untouched, and labels the destructive action `Clear sample saves only`.
- Verification:
  - `git diff --check` passed.
  - Debug generic iOS Simulator build passed with `CODE_SIGNING_ALLOWED=NO`.

### 2026-05-08 22:59 CEST - GitHub preflight workflow

- Owner: current Codex chat
- Status: completed at 2026-05-08 23:04 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-08.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/PreflightAutomation.md`
  - `/Users/guest1/Documents/SAVI-iOS/.github/workflows/`
- Notes:
  - Add a credential-free GitHub Actions workflow for quick preflight and optional manual build gates.
  - Do not add secrets, uploads, signing, or App Store Connect actions.
  - Avoid app/share-extension code; this is automation/docs only.
- Result:
  - Added `.github/workflows/savi-preflight.yml`.
  - Added `Docs/Architecture/Runbooks/GitHubActions.md`.
  - Linked the workflow from preflight automation, CTO handoff, and today's changelog.
  - The workflow runs quick preflight on pull requests and pushes to `main`/`develop`, plus optional manual `run_builds` for iOS Release and `SAVI Mac` build checks.
- Verification:
  - YAML parsed successfully with Ruby.
  - `scripts/savi-preflight.sh` passed.
  - `git diff --check` passed.
  - No secrets, signing, TestFlight upload, App Store Connect keys, Supabase credentials, or PostHog credentials were added.

### 2026-05-08 22:58 CEST - Share extension preview-card alignment pass

- Owner: current Codex chat
- Status: completed at 2026-05-08 22:59 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/SAVIShareExtension/ShareViewController.swift`
- Notes:
  - Keep the improved folder grid.
  - Rework the preview/title/tag/note area above folders for better alignment, larger thumbnail, more readable long titles, and smaller secondary controls.
  - Focused UI/build pass only; no TestFlight upload.
- Result:
  - Increased the share preview thumbnail from 60 to 72 points and aligned it as the visual anchor.
  - Moved the edit-title control into the metadata row as a compact icon button so it stops stealing title space.
  - Added dynamic title sizing: short titles stay bold, longer titles scale down and can use four lines.
  - Tightened the tag input, plus button, and note controls so the top card feels less bulky above the folder grid.
- Verification:
  - `git diff --check` passed.
  - Debug generic iOS Simulator build passed with `CODE_SIGNING_ALLOWED=NO`.

### 2026-05-08 22:50 CEST - Unified preflight automation

- Owner: current Codex chat
- Status: completed at 2026-05-08 22:58 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-08.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/CTOHandoffIndex.md`
  - `/Users/guest1/Documents/SAVI-iOS/scripts/`
- Notes:
  - Other chat currently owns share-extension dark-mode folder readability; avoid app/share-extension UI files.
  - Add a single preflight command that runs diff, safety, backend/social readiness, and optional Release/Mac builds.
  - Documentation/scripts only; no app code or backend credential changes.
- Result:
  - Added `scripts/savi-preflight.sh`.
  - Added `Docs/Architecture/Runbooks/PreflightAutomation.md`.
  - Linked the preflight command from release governance, CTO handoff, and today's changelog.
  - The preflight command supports quick checks by default and optional `--release-build`, `--mac-debug-build`, `--mac-release-build`, and `--all-builds` gates.
- Verification:
  - `scripts/savi-preflight.sh` passed.
  - `git diff --check` passed.
  - Public-site TODO reminders appeared as expected because domain/legal setup is not done yet.
  - No app code, share-extension UI, or backend credentials were changed.

### 2026-05-08 22:49 CEST - Share extension dark-mode folder readability pass

- Owner: current Codex chat
- Status: completed at 2026-05-08 22:54 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/SAVIShareExtension/ShareViewController.swift`
- Notes:
  - Simplify the Share Sheet folder picker in night mode.
  - Make the selected folder unmistakable with a stronger selected state and quieter unselected folder colors.
  - Avoid broad QA/TestFlight work for this focused UI pass.
- Result:
  - Folder summary card now stays neutral in dark mode instead of inheriting noisy folder tint.
  - Folder tiles now use a consistent neutral surface, small muted category strip, stronger selected lime border, and selected subtitle (`Selected` / `Smart picker`).
  - Unselected folder icon/text treatment is quieter so the selected tile reads first.
- Verification:
  - `git diff --check` passed.
  - Debug generic iOS Simulator build passed with `CODE_SIGNING_ALLOWED=NO`.

### 2026-05-08 22:48 CEST - Backend/social readiness validator

- Owner: current Codex chat
- Status: completed at 2026-05-08 22:55 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-08.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/Runbooks/ReleaseGovernance.md`
  - `/Users/guest1/Documents/SAVI-iOS/scripts/`
- Notes:
  - Existing app already has mock social UI/actions behind `SaviReleaseGate.socialFeaturesEnabled`.
  - Add an automated readiness check for contracts, Supabase RLS draft, release social gate, and social safety docs.
  - Documentation/scripts only; no app UI or backend credential changes.
- Result:
  - Added `scripts/savi-backend-readiness-check.py`.
  - Extended `scripts/savi-safety-scan.sh` to check the new OpenAPI/schema/PostHog/Supabase contract docs.
  - Updated release governance, CTO handoff docs, and today's changelog to include the new readiness gate.
- Verification:
  - `scripts/savi-backend-readiness-check.py` passed.
  - `scripts/savi-safety-scan.sh` passed.
  - `git diff --check` passed.
  - No app code or backend credentials were changed.

### 2026-05-08 22:44 CEST - Credential-free backend, legal, social UX, and safety prep

- Owner: current Codex chat
- Status: completed at 2026-05-08 22:52 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-08.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/PublicSite/`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Backend/`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/`
  - `/Users/guest1/Documents/SAVI-iOS/scripts/`
- Notes:
  - Build the credential-free foundation before domain/Supabase/PostHog accounts exist.
  - Add legal/support page templates, OpenAPI/JSON contracts, Supabase RLS test plan, PostHog dashboard specs, social/mobile/notification basics, mock admin/social specs, and local safety scan scripts.
  - Documentation/scripts only; avoid app UI/code changes and do not touch other-chat dirty app files.
- Result:
  - Added public-site templates for privacy, terms, support, data deletion, community guidelines, and domain/DNS planning.
  - Added Social V1 OpenAPI contract, JSON schemas for item/public link/analytics event, Supabase RLS test plan, PostHog dashboard spec, social mobile UX/notification rules, and mock social/admin flow specs.
  - Added `scripts/savi-safety-scan.sh` for local checks around founder/admin strings, likely secrets, and documentation front doors.
  - Linked the new files from architecture/backend front doors and today's changelog.
- Verification:
  - `scripts/savi-safety-scan.sh` passed.
  - JSON schema/dashboard files validated with `python3 -m json.tool`.
  - `git diff --check` passed.
  - No app code was changed for this credential-free foundation pass.

### 2026-05-08 22:19 CEST - Master roadmap, compliance, social, and desktop governance

- Owner: current Codex chat
- Status: completed at 2026-05-08 22:23 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-08.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/`
- Notes:
  - Add the unified master execution layer for CTO handoff, Apple compliance, Social V1, desktop/founder hub, and living-doc governance.
  - Documentation-only pass; do not change app code or TestFlight behavior.
  - Keep current TestFlight private-save-first with social hidden.
- Result:
  - Added `CTOHandoffIndex.md`, `MasterRoadmap.md`, `AppStoreComplianceMatrix.md`, `SocialV1ImplementationPlan.md`, and `DesktopAndFounderHubRoadmap.md`.
  - Updated architecture README and setup/release runbooks to point to the new master docs.
  - Updated today's changelog with the new governance layer.
- Verification:
  - `git diff --check` passed.
  - Confirmed all five new master docs exist.
  - Confirmed compliance/social/desktop docs mention the key Apple and security gates: privacy policy, privacy labels, account deletion, Sign in with Apple, report/block/moderation, support, age rating, export, App Review notes, RLS, service-role separation, PostHog Query separation, Founder Hub separation, and Android readiness.
  - No app code was changed for this documentation-only pass.

### 2026-05-08 22:10 CEST - Senior architecture documentation package

- Owner: current Codex chat
- Status: completed at 2026-05-08 22:16 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-08.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Architecture/`
- Notes:
  - Implement the senior architecture plan as repo-tracked docs/guidelines, not app behavior changes.
  - Capture local-first iOS, Supabase social/sync, PostHog analytics, optional iCloud backup, Mac-only Founder Hub, and Android readiness.
  - Do not touch iOS app code or other-chat dirty UI/build changes unless needed.
- Result:
  - Added `Docs/Architecture/` as the CTO/future-engineer architecture package.
  - Added system context, client architecture, backend architecture, data model, API contract, analytics, security/privacy, Android readiness, setup checklist, and release governance docs.
  - Added ADRs for native clients/shared backend contract, Supabase/PostHog/CloudKit roles, and Founder Hub/admin separation.
  - Linked the architecture package from `Docs/Backend/README.md`.
- Verification:
  - `git diff --check` passed.
  - Confirmed 13 architecture files were added under `Docs/Architecture/`.
  - No app code was changed for this documentation-only pass.

### 2026-05-08 22:02 CEST - Founder Hub Mac-only security separation

- Owner: current Codex chat
- Status: completed at 2026-05-08 22:06 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-08.md`
  - `/Users/guest1/Documents/SAVI-iOS/Shared/SaviCompanionCore.swift`
  - `/Users/guest1/Documents/SAVI-iOS/SAVIMac/SaviFounderDashboardCore.swift`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI.xcodeproj/project.pbxproj`
- Notes:
  - Move Founder Hub dashboard models and mock metrics out of the shared iOS/Mac core.
  - Keep Founder Hub UI and dashboard data compiled only into the `SAVI Mac` target.
  - Verify iOS Release/TestFlight no longer compiles `SaviFounder` dashboard symbols.
- Result:
  - Added `SAVIMac/SaviFounderDashboardCore.swift` and moved Founder Hub dashboard models/mock data into it.
  - Removed all `SaviFounder` dashboard symbols from `Shared/SaviCompanionCore.swift`.
  - Added the new file to the `SAVI Mac` source phase only.
  - iOS/TestFlight source still compiles the shared companion core, but no founder dashboard models, mock business metrics, or Founder Hub strings.
- Verification:
  - `rg "SaviFounder" Shared/SaviCompanionCore.swift` returned no matches.
  - `rg "SaviFounder|Founder Hub|Saves/User|Mock active testers|Rabbit Hole Radar|TestFlight Room|Codex Workshop|PostHog query" SAVI SAVIShareExtension Shared` returned no matches.
  - `git diff --check` passed.
  - `SAVI Mac` Debug macOS build passed.
  - `SAVI Mac` Release macOS build passed.
  - iOS `SAVI` Release generic iPhoneOS no-sign build passed.
  - Secret scan found only intentional guardrail text and no actual admin keys, PostHog personal API keys, Supabase service-role keys, passwords, or private-content tracking.

### 2026-05-08 21:14 CEST - Mac Founder Hub dashboards and Codex skills

- Owner: current Codex chat
- Status: completed at 2026-05-08 21:22 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-08.md`
  - `/Users/guest1/Documents/SAVI-iOS/Shared/SaviCompanionCore.swift`
  - `/Users/guest1/Documents/SAVI-iOS/SAVIMac/SAVIMacRootView.swift`
  - `/Users/guest1/.codex/skills/`
- Notes:
  - Add a native Mac Founder Hub dashboard area with mock/privacy-safe metrics first.
  - Keep iOS Release/TestFlight behavior unchanged.
  - Install the selected curated Codex skills for security, QA, crash/debug, and team workflow.
- Result:
  - Added the Mac-only Founder Hub as the default `SAVI Mac` landing screen.
  - Added shared founder dashboard models and a mock privacy-safe dashboard provider.
  - Added SAVI-style dashboard rooms: Pulse, Share Sheet Rocket, Save Engine, Search Brain, Rabbit Hole Radar, Social Lab, Reliability Room, TestFlight Room, and Codex Workshop.
  - Added native Swift Charts, activation funnel, retention grid, ranked lists, and status/alert rows.
  - Added a disabled Mac-only PostHog dashboard client path that checks future Keychain status, makes no live calls, and stores no keys in source.
  - Installed the selected curated Codex skills: `security-threat-model`, `security-best-practices`, `sentry`, `playwright`, `screenshot`, `gh-fix-ci`, `gh-address-comments`, and `yeet`.
- Verification:
  - Curated skill install check confirmed all eight skills installed.
  - `git diff --check` passed before build verification.
  - `SAVI Mac` Debug macOS build passed.
  - `SAVI Mac` Release macOS build passed.
  - iOS `SAVI` Release generic iPhoneOS no-sign build passed.
  - Debug Mac app launched and screenshot was saved to `/Users/guest1/Documents/SAVI-iOS/build/qa/mac-founder-hub/savi-mac-founder-hub-20260508-2121.png`.
  - Secret scan found only intentional guardrail text and no actual PostHog personal API key, Supabase service-role key, passwords, or private-content tracking.

### 2026-05-08 18:13 CEST - Mac companion development target

- Owner: current Codex chat
- Status: completed at 2026-05-08 18:18 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-08.md`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI.xcodeproj/project.pbxproj`
  - `/Users/guest1/Documents/SAVI-iOS/Shared/SaviCompanionCore.swift`
  - `/Users/guest1/Documents/SAVI-iOS/SAVIMac/`
- Notes:
  - Add a separate macOS SwiftUI companion target instead of changing the iPhone target to Catalyst.
  - Keep iOS Release/TestFlight behavior unchanged and avoid reverting other-chat dirty files.
  - Build a local/mock Mac v1 first; Supabase/PostHog remain disabled without config.
- Result:
  - Added a new `SAVI Mac` macOS SwiftUI target, shared scheme, sandbox entitlements, and development-only desktop companion shell.
  - Added `Shared/SaviCompanionCore.swift` with companion-safe models, search/filtering, mock sample data, safe config loading, and disabled/stubbed social/analytics clients.
  - Mac v1 can browse mock saves, search, inspect item details, open web links, export/import JSON through user-selected panels, and view sync/analytics/debug status.
  - iOS Release/TestFlight behavior was not changed; Supabase/PostHog remain disabled unless safe public config is added later.
- Verification:
  - `git diff --check` passed before documentation checkpoint.
  - `SAVI Mac` Debug macOS build passed.
  - `SAVI Mac` Release macOS build passed.
  - Debug Mac app launched and smoke screenshot was saved to `/Users/guest1/Documents/SAVI-iOS/build/qa/mac-companion/savi-mac-smoke-20260508-181644.png`.
  - iOS `SAVI` Release generic iPhoneOS no-sign build passed.
  - iOS `SAVI` Debug generic iOS Simulator build passed with isolated DerivedData.

### 2026-05-08 17:47 CEST - Social/analytics/backend foundation

- Owner: current Codex chat
- Status: completed at 2026-05-08 18:06 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-08.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Backend/`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Core/SaviCore.swift`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Views/Profile/ProfileAndFriends.swift`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Views/Root/NativeSaviRootView.swift`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Views/Search/SearchScreen.swift`
- Notes:
  - Implementing the safe first pass for Supabase/PostHog-ready architecture without live accounts or secrets.
  - Release/TestFlight must remain social-off and analytics no-op unless later explicitly configured.
  - Avoiding Xcode project rewrites while other chats have dirty project/asset changes.
- Result:
  - Added typed analytics/backend/social interfaces, safe config loading, Release no-op services, and Debug mock/console services.
  - Added an opt-in Profile analytics privacy card plus local Debug event viewer; no live PostHog SDK or autocapture was added.
  - Routed social sync/profile/link actions through `SaviSocialBackendService`; CloudKit is no longer used for social paths and remains reserved for optional private Apple backup later.
  - Added Supabase Social V1 schema/RLS draft, PostHog dashboard plan, analytics event catalog, App Store safety checklist, backend config template, and macOS companion architecture docs under `Docs/Backend/`.
- Verification:
  - `git diff --check` passed.
  - Release generic iPhoneOS no-sign build passed.
  - Debug generic iOS Simulator build passed.
  - Confirmed active `SAVI/` code no longer calls old CloudKit social sync methods.

### 2026-05-08 17:31 CEST - Build 33 and tester automation status

- Owner: current Codex chat
- Status: active coordination; TestFlight build valid; tester watcher running
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
- Build:
  - Current candidate is `SAVI 1.0 (33)`.
  - App Store Connect build id: `122ed7a9-4396-4d31-a318-e842e75ae0e8`.
  - Processing state: `VALID`.
  - TestFlight state: `BETA_INTERNAL_TESTING`.
  - Latest archive: `/Users/guest1/Documents/SAVI-iOS/build/qa/archives/SAVI-20260508-152458-b33.xcarchive`.
- Notes:
  - Latest uploaded build includes image preview pinch-zoom fixes, unified share-extension folder tiles, larger/better-aligned share-extension thumbnail/title area, and social still disabled for Release/TestFlight.
  - Verified App Store Connect app name: `SAVI: Save Now, Find Later.`
  - Verified feedback email: `1080solutionsA@gmail.com`.
  - Verified beta description starts with `save it now, find it later.` and uses the user-approved “that link you swore you’d find again...” copy.
  - Tester automation `invite-nelson-after-savi-approval` is running every 5 minutes and should keep watching accepted Users and Access invites.
- Tester automation state:
  - Already accepted and added to `SAVI Internal`: `jsuero@mstn.com`, `nahomi@yoyocolectivo.com`.
  - Existing internal testers also include `altatecrd@gmail.com`, `philippheller@gmx.de`, `matti.lamminsalo@gmail.com`, `andreusbl@mac.com`, `Andresaquinob@gmail.com`, `jmandrickson@gmail.com`, and `Gapm89@gmail.com`.
  - Still pending Apple Users and Access acceptance: `andreusbl@icloud.com`, `Andreuslif@gmail.com`, `Luimi2k1@gmail.com`, `j.rodriguez28@icloud.com`, `Jordanasherman121@hotmail.com`, `Nelson.bello@aderca.com`, `Gerardo@luxiard.com`, and `andreus@lif.group`.
  - Latest watcher check at 2026-05-08 17:37 CEST found all 8 pending invites unexpired and not yet available as beta testers.
- Coordination:
  - Use this file before answering SAVI status or editing shared files.
  - Add a new entry for every active task or update this entry when the tester watcher changes state.

### 2026-05-08 17:25 CEST - Cross-chat coordination rule refresh

- Owner: current Codex chat
- Status: completed
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/AGENTS.md`
- Notes:
  - User asked that parallel chats always check/write the shared log or changelog so both chats stay current.
  - Standing rule clarified: use this handoff log for every task; use dated changelog for meaningful app/build/TestFlight changes.

### 2026-05-08 13:37 CEST - Build 31 manual title protection

- Owner: current Codex chat
- Status: uploaded; App Store Connect processing
- Build: `SAVI 1.0 (31)`
- Archive:
  `/Users/guest1/Documents/SAVI-iOS/build/qa/archives/SAVI-20260508-133246-b31.xcarchive`
- Archive log:
  `/Users/guest1/Documents/SAVI-iOS/build/qa/logs/SAVI-20260508-133246-b31-archive.log`
- Export/upload dir:
  `/Users/guest1/Documents/SAVI-iOS/build/qa/export-b31-20260508-133246`
- Upload log:
  `/Users/guest1/Documents/SAVI-iOS/build/qa/logs/SAVI-20260508-133246-b31-upload.log`
- Notes:
  - Fixed share-extension edited titles being overwritten by later metadata refresh.
  - `PendingShare` now carries `title_edited`; `SaviItem` persists `titleEdited`.
  - Metadata enrichment still updates thumbnails/source/tags/folder, but skips title replacement once the title was manually edited.
  - Main-app item edits also mark the title as protected when changed.
- Verification:
  - `git diff --check` passed.
  - Debug simulator build passed.
  - Release archive succeeded.
  - Upload ended with `Uploaded SAVI` and `** EXPORT SUCCEEDED **`.

### 2026-05-08 13:12 CEST - Build 30 TestFlight upload

- Owner: current Codex chat
- Status: uploaded; App Store Connect processing
- Build: `SAVI 1.0 (30)`
- Archive:
  `/Users/guest1/Documents/SAVI-iOS/build/qa/archives/SAVI-20260508-130659-b30.xcarchive`
- Archive log:
  `/Users/guest1/Documents/SAVI-iOS/build/qa/logs/SAVI-20260508-130659-b30-archive.log`
- Export/upload dir:
  `/Users/guest1/Documents/SAVI-iOS/build/qa/export-b30-20260508-130659`
- Upload log:
  `/Users/guest1/Documents/SAVI-iOS/build/qa/logs/SAVI-20260508-130659-b30-upload.log`
- Notes:
  - Release/TestFlight app remains `com.altatecrd.savi` with social disabled.
  - Updated build includes the onboarding/share setup cleanup, no large first-home sample overlay, solid `Memes & LOLZ` folder card, and softer folder text/icon ink.
  - Tester-facing copy in `Docs/TestFlightReadiness.md` now explains what SAVI does, how to test, and asks testers to send feedback personally or to `1080solutionsA@gmail.com` with thanks for helping build SAVI.
  - Upload ended with `Uploaded SAVI` and `** EXPORT SUCCEEDED **`.

### 2026-05-08 11:25 CEST - Onboarding phone frame and Share Sheet setup cleanup

- Owner: current Codex chat
- Status: completed; debug simulator build passed
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Views/Components/AppComponents.swift`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Core/SaviCore.swift`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Assets.xcassets/share-setup-savi-app-row.imageset/`
- Notes:
  - Rework onboarding fake phone screenshots so the frame notch/status treatment
    does not cover useful app screenshot content.
  - Simplify the Share Sheet setup guide so the practice/open share action reads
    like one clear final action instead of several competing buttons.
  - Confirmed onboarding slide screenshot order in simulator: Home, Folders,
    Search, Share Sheet/SAVI app row.
  - Removed the large first-home sample-library overlay; the smaller inline
    sample notice remains.
  - Reverted the launch folder cover for `f-lmao` to a solid lime card and
    renamed it `Memes & LOLZ` for clearer launch readability.
  - Verification: `git diff --check`; Debug generic iOS Simulator build passed.

### 2026-05-08 11:05 CEST - Build 29 uploaded to TestFlight

- Owner: current Codex chat
- Status: uploaded; App Store Connect processing at 2026-05-08 11:14 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI.xcodeproj/project.pbxproj`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Info.plist`
  - `/Users/guest1/Documents/SAVI-iOS/SAVIShareExtension/Info.plist`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Views/Components/AppComponents.swift`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Views/Home/HomeScreen.swift`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Assets.xcassets/onboarding-share-extension-real.imageset/onboarding-share-extension-real.png`
- Notes:
  - Bumped main app and share extension build number to `SAVI 1.0 (29)`.
  - `git diff --check` passed.
  - Debug simulator build passed.
  - Both simulator channels were refreshed from the same source before the
    archive attempt:
    - `SAVI 1.0 (28)` / `com.altatecrd.savi`
    - `SAVI Test 1.0 (28)` / `com.altatecrd.savi.personaldebug`
  - Release archive succeeded for the main `SAVI` app, not `SAVI Test`.
  - Initial TestFlight upload failed until App Store Connect credentials were
    refreshed in Xcode.
  - Retried upload succeeded; App Store Connect responded that the uploaded
    package is processing.
  - Archive:
    `/Users/guest1/Documents/SAVI-iOS/build/qa/archives/SAVI-20260508-105811-b29.xcarchive`
  - Archive log:
    `/Users/guest1/Documents/SAVI-iOS/build/qa/logs/SAVI-20260508-105811-b29-archive.log`
  - Upload log:
    `/Users/guest1/Documents/SAVI-iOS/build/qa/logs/SAVI-20260508-105811-b29-export-upload.log`
  - Next action: confirm `SAVI 1.0 (29)` has finished processing in App Store
    Connect.
  - Post-processing task requested by user: after build `29` is fully
    available/confirmed, not merely processing, invite `jmandrickson@gmail.com`.

### 2026-05-08 08:03 CEST - Build 26 TestFlight upload

- Owner: current Codex chat
- Status: uploaded; App Store Connect processing at 2026-05-08 08:04 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/TestFlightReadiness.md`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI.xcodeproj/project.pbxproj`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Info.plist`
  - `/Users/guest1/Documents/SAVI-iOS/SAVIShareExtension/Info.plist`
- Notes:
  - Bumped main app and share extension build number to `SAVI 1.0 (26)`.
  - `git diff --check` passed.
  - Release generic iPhoneOS build succeeded.
  - Release archive succeeded for the main `SAVI` app, not `SAVI Test`.
  - Uploaded `SAVI 1.0 (26)` to App Store Connect/TestFlight; upload ended with
    `Uploaded SAVI` and `EXPORT SUCCEEDED`.
  - Archive:
    `/Users/guest1/Documents/SAVI-iOS/build/qa/archives/SAVI-20260508-080211-b26.xcarchive`
  - Build log:
    `/Users/guest1/Documents/SAVI-iOS/build/qa/logs/SAVI-release-build-b26-20260508-080040.log`
  - Archive log:
    `/Users/guest1/Documents/SAVI-iOS/build/qa/logs/SAVI-archive-build26-20260508-080211.log`
  - Upload log:
    `/Users/guest1/Documents/SAVI-iOS/build/qa/logs/SAVI-export-upload-build26-20260508-080332.log`

### 2026-05-08 08:05 CEST - TestFlight metadata cleanup

- Owner: current Codex chat
- Status: complete; App Store Connect metadata saved at 2026-05-08 08:10 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/TestFlightReadiness.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
- Notes:
  - Update the canonical TestFlight copy so the app name is
    `SAVI: Save Now, Find Later`.
  - Front-load the Beta Description with what SAVI does so testers understand
    it before tapping See More.
  - App Store Connect App Information name saved as
    `SAVI: Save Now, Find Later`.
  - App Store version Promotional Text and Description were updated with
    what-SAVI-does-first copy.
  - TestFlight Test Information Beta App Description was updated and saved.
  - Build `1.0 (25)` What to Test was updated and saved.
  - Feedback email remains `1080solutionsA@gmail.com`.

### 2026-05-08 07:12 CEST - Build 25 archive export loading and TestFlight push

- Owner: current Codex chat
- Status: uploaded; App Store Connect processing at 2026-05-08 07:23 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI.xcodeproj/project.pbxproj`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Core/SaviCore.swift`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Views/Profile/ProfileAndFriends.swift`
- Notes:
  - Fix full archive export so users see a clear loading/preparing state and the iOS share sheet opens reliably after the export options sheet dismisses.
  - Bumped main/TestFlight build to `SAVI 1.0 (25)`.
  - Fixed the LOLZ folder cover renderer so image-background folders fill the folder tile instead of only showing a tiny icon.
  - `git diff --check` passed.
  - Debug simulator build passed and `SAVI Test` was refreshed on the booted simulator.
  - Release archive succeeded for the main `SAVI` app, not `SAVI Test`.
  - Uploaded `SAVI 1.0 (25)` to App Store Connect/TestFlight; upload ended with
    `Uploaded SAVI` and `EXPORT SUCCEEDED`.
  - Archive:
    `/Users/guest1/Documents/SAVI-iOS/build/qa/archives/SAVI-20260508-072115-b25.xcarchive`
  - Upload log:
    `/Users/guest1/Documents/SAVI-iOS/build/qa/logs/SAVI-export-upload-build25-20260508-072231.log`

### 2026-05-07 22:55 CEST - Build 24 LOLZ folder cover upload

- Owner: current Codex chat
- Status: uploaded; App Store Connect processing at 2026-05-07 22:55 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI.xcodeproj/project.pbxproj`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Assets.xcassets/folder-cover-lolz.imageset`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Services/LegacyAndUtilities.swift`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Core/SaviCore.swift`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Views/Components/AppComponents.swift`
  - `/Users/guest1/Documents/SAVI-iOS/SAVIShareExtension/ShareItemExtractor.swift`
  - `/Users/guest1/Documents/SAVI-iOS/SAVIShareExtension/ShareViewController.swift`
  - `/Users/guest1/Documents/SAVI-iOS/Shared/AppGroupSupport.swift`
- Notes:
  - Replaced the old memes folder cover asset with a resized/re-encoded
    `folder-cover-lolz` image asset and renamed the default folder to `LOLZ`.
  - Bumped folder layout repair to version 6 so existing simulator/device data
    rewrites the old `Memes & LOLs` folder name and cover.
  - Verified on booted `SAVI Fresh iPhone 17`
    (`97C29851-BACC-46AB-899E-774EC2B0287E`) that persisted data now shows
    `f-lmao` as `LOLZ` with image background enabled.
  - `git diff --check` passed.
  - Debug simulator build passed.
  - Release archive succeeded for `SAVI 1.0 (24)`.
  - Uploaded `SAVI 1.0 (24)` to App Store Connect/TestFlight; upload ended with
    `Uploaded SAVI` and `EXPORT SUCCEEDED`.
  - Archive:
    `/Users/guest1/Documents/SAVI-iOS/build/qa/archives/SAVI-20260507-225115-b24.xcarchive`
  - Upload log:
    `/Users/guest1/Documents/SAVI-iOS/build/qa/logs/SAVI-export-upload-build24-20260507-225319.log`

### 2026-05-07 19:50 CEST - Build 23 photo/file share save fix and upload

- Owner: current Codex chat
- Status: uploaded; App Store Connect processing at 2026-05-07 19:50 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-07.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI.xcodeproj/project.pbxproj`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Core/SaviCore.swift`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/SAVI-PersonalDebug.entitlements`
  - `/Users/guest1/Documents/SAVI-iOS/SAVIShareExtension/SAVIShareExtension-PersonalDebug.entitlements`
  - `/Users/guest1/Documents/SAVI-iOS/SAVIShareExtension/Info.plist`
  - `/Users/guest1/Documents/SAVI-iOS/SAVIShareExtension/ShareItemExtractor.swift`
  - `/Users/guest1/Documents/SAVI-iOS/SAVIShareExtension/ShareViewController.swift`
  - `/Users/guest1/Documents/SAVI-iOS/Shared/AppGroupSupport.swift`
- Notes:
  - User reported that `Save now` did nothing and iPhone-shot image shares
    could fail to show/save before the next TestFlight update.
  - Result: `SAVI Test` now has a debug App Group, fixing the simulator-only
    silent save failure caused by missing debug entitlements.
  - Result: storage migrates from legacy Documents storage into App Group
    storage when the shared container becomes available.
  - Result: Share Extension activation/extraction covers image, file, movie,
    audio, PDF, text, URL, and mixed attachments.
  - Verified on `SAVI Fresh iPhone 17`
    (`97C29851-BACC-46AB-899E-774EC2B0287E`): Photos-origin image share showed
    SAVI/SAVI Test in the iOS Share Sheet, loaded the real thumbnail in the
    Share Extension, and saved an image item into shared storage.
  - Installed Release `SAVI 1.0 (23)` and `SAVI Share 23` on the same simulator.
  - `git diff --check` passed.
  - Release generic iPhoneOS no-sign build passed.
  - Signed archive succeeded:
    `/Users/guest1/Documents/SAVI-iOS/build/qa/archives/SAVI-20260507-194628-b23.xcarchive`.
  - Uploaded `SAVI 1.0 (23)` to App Store Connect/TestFlight; upload ended with
    `Uploaded SAVI` and `EXPORT SUCCEEDED`, now processing.
  - Logs:
    - `/Users/guest1/Documents/SAVI-iOS/build/qa/logs/SAVI-archive-build23-20260507-194628.log`
    - `/Users/guest1/Documents/SAVI-iOS/build/qa/logs/SAVI-export-upload-build23-20260507-194848.log`

### 2026-05-07 18:35 CEST - Share Sheet reference polish and build 22 upload

- Owner: current Codex chat
- Status: completed at 2026-05-07 18:41 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-07.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI.xcodeproj/project.pbxproj`
  - `/Users/guest1/Documents/SAVI-iOS/SAVIShareExtension/ShareItemExtractor.swift`
  - `/Users/guest1/Documents/SAVI-iOS/SAVIShareExtension/ShareViewController.swift`
  - `/Users/guest1/Documents/SAVI-iOS/build/qa/SAVI-export-build22.plist`
- Notes:
  - Fast visual target: make the Share Extension screen match the provided clean reference and prove the practice image thumbnail loads.
  - Result: Share Extension now uses the softer card/background treatment, compact tag input, note card, and reference folder order/labels.
  - Result: `SAVI Share Sheet Practice` now displays the real practice image thumbnail in the Share Extension instead of the generic image icon.
  - Verification: `git diff --check` passed, Release generic iPhoneOS no-sign build passed, and Debug simulator visual QA screenshot confirmed the thumbnail and folder layout:
    `/var/folders/p2/b94vt2zd7kd1xd9q9fcdsj800000gp/T/screenshot_optimized_209ea01b-5fa0-4e82-80d0-c0e7d5b4de80.jpg`.
  - TestFlight: uploaded `SAVI 1.0 (22)` to App Store Connect; upload succeeded and the package began processing.
  - Archive:
    `/Users/guest1/Documents/SAVI-iOS/build/qa/archives/SAVI-20260507-183717-b22.xcarchive`
  - Logs:
    - `/Users/guest1/Documents/SAVI-iOS/build/qa/logs/SAVI-archive-build22-20260507-183717.log`
    - `/Users/guest1/Documents/SAVI-iOS/build/qa/logs/SAVI-export-upload-build22-20260507-183929.log`

### 2026-05-07 16:15 CEST - Profile UI sweep and SAVI First Save verification

- Owner: current Codex chat
- Status: completed at 2026-05-07 16:45 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Core/SaviCore.swift`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Views/Profile/ProfileAndFriends.swift`
  - `/Users/guest1/Documents/SAVI-iOS/SAVIShareExtension/ShareItemExtractor.swift`
- Notes:
  - Clean the TestFlight/non-social Profile layout, hide raw support/account emails from visible UI, and harden/verify the `SAVI First Save` thumbnail/data path.
  - Result: Release/TestFlight Profile is now grouped around setup/actions, secondary settings, and hidden social; raw support/account emails are no longer shown as large visible UI text.
  - Result: `SAVI First Save` is deterministic through both the in-app practice save path and share/import normalization: title `SAVI First Save`, source `Photos`, folder `Life Admin`, PNG thumbnail, PNG asset, 1170x2532 dimensions, and tags `first-save`, `share-sheet`, `practice`, `image`, `getting-started`.
  - Verification: `git diff --check` passed, Debug simulator build/install passed on fresh `SAVI Fresh iPhone 17`, storage inspection confirmed thumbnail bytes and asset metadata, and Release generic iPhoneOS no-sign build passed. No TestFlight upload was performed.

### 2026-05-07 16:06 CEST - TestFlight Profile layout cleanup

- Owner: current Codex chat
- Status: completed at 2026-05-07 16:09 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Views/Profile/ProfileAndFriends.swift`
- Notes:
  - Fast UI loop only: clean the non-social/TestFlight Profile page hierarchy and layout. No TestFlight upload unless explicitly requested.
  - Result: Release/TestFlight Profile now leads with a compact beta summary, a 2x2 setup/action grid, and a quieter direct Help & Feedback row before privacy/backup/library.
  - Result: Social remains hidden in Release and only appears as a small coming-later teaser at the bottom.
  - Verification: `git diff --check` passed and Release iPhone Simulator no-sign build passed.

### 2026-05-07 15:42 CEST - Onboarding copy and practice image import fix

- Owner: current Codex chat
- Status: completed at 2026-05-07 16:02 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Design/SampleLibrarySources.md`
  - `/Users/guest1/Documents/SAVI-iOS/Shared/AppGroupSupport.swift`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Core/SaviCore.swift`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Views/Components/AppComponents.swift`
  - `/Users/guest1/Documents/SAVI-iOS/SAVIShareExtension/ShareItemExtractor.swift`
  - onboarding screenshot assets in `/Users/guest1/Documents/SAVI-iOS/SAVI/Assets.xcassets`
- Notes:
  - Fast UI loop only: bolder onboarding copy, real app screenshots for welcome visuals, and deterministic practice image title/thumbnail.
  - Result: onboarding now uses bolder friend-facing copy plus real Home/Search simulator screenshots.
  - Result: bundled practice save is now named `SAVI First Save`.
  - Result: image shares now emit `data:image/...` thumbnails and preserve friendly filenames in the shared app group, fixing the orange placeholder/UUID-name issue.
  - Verification: fast Debug simulator build/install passed; no Release archive or TestFlight upload was run.

### 2026-05-07 15:22 CEST - Profile account privacy cleanup

- Owner: current Codex chat
- Status: completed at 2026-05-07 15:30 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Core/SaviCore.swift`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Views/Profile/ProfileAndFriends.swift`
- Notes:
  - Fast UI loop only: hide the raw Apple/account email from prominent Profile UI and verify with one Debug simulator screenshot.
- Result:
  - `appleAccountDisplayName` no longer falls back to the raw email; linked accounts show the full name when available or `Apple ID linked`.
  - `appleAccountDetail` now says the email is saved privately instead of rendering the email inline.
  - Added a compact `Copy account email` pill in the account panel so the email is available only by explicit action.
  - `git diff --check` passed.
  - Debug `SAVI Test` build/install passed on iPhone 17 Pro simulator `C99532A0-7EE8-4078-B821-703387BCFBD5`.
  - Profile screenshot saved at `/Users/guest1/Desktop/SAVI_QA/profile-cleanup/profile-top-v2.jpg`.
  - No Release/archive/TestFlight upload was performed.

### 2026-05-07 15:00 CEST - Onboarding story and setup flow polish

- Owner: current Codex chat
- Status: completed at 2026-05-07 15:20 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Design/SampleLibrarySources.md`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Core/SaviCore.swift`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Views/Components/AppComponents.swift`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Views/Profile/ProfileAndFriends.swift`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Assets.xcassets/onboarding-home-real.imageset`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Assets.xcassets/onboarding-folders-real.imageset`
- Notes:
  - Fast UI loop only: Debug `SAVI Test` on one current-size simulator with screenshots. No Release/archive/TestFlight gate.
  - Rework onboarding copy/visuals, Share Sheet setup order, and Profile guide/reset grouping.
- Result:
  - Reworked welcome cards to lead with `Save it now. Find it later.`, a native digital-life visual, SAVI Brain/share-extension visual, real folder-name grid, and the Share Sheet as the final mandatory setup step.
  - Moved the Share Sheet practice/open button below the three setup instruction cards; verified it opens the real iOS Share Sheet with the practice image.
  - Added `Guide & Setup` in Profile with replay welcome cards, Share Sheet setup, quick tour, and reset tab tips.
  - Removed stale generated home/folders onboarding image assets now replaced by native SwiftUI visuals.
  - `git diff --check` passed.
  - Debug `SAVI Test` build/install passed on iPhone 17 Pro simulator `C99532A0-7EE8-4078-B821-703387BCFBD5`; screenshots saved under `/Users/guest1/Desktop/SAVI_QA/onboarding-polish/`.
  - No Release/archive/TestFlight upload was performed.

### 2026-05-07 17:23 CEST - Build 20 TestFlight upload

- Owner: current Codex chat
- Status: completed at 2026-05-07 17:23 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/SAVI.xcodeproj/project.pbxproj`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Core/SaviCore.swift`
  - `/Users/guest1/Documents/SAVI-iOS/SAVI/Views/Components/AppComponents.swift`
  - `/Users/guest1/Documents/SAVI-iOS/SAVIShareExtension/ShareViewController.swift`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/ChangeLog/2026-05-07.md`
- Notes:
  - Build 19 uploaded first, then a last-minute first-save/share-setup fix required build 20.
  - `SAVI` Release remains the TestFlight/pilot app; `SAVI Test` remains debug/social-enabled local only.
- Result:
  - Bumped app and share extension build settings to `20`.
  - Installed both simulator channels on `SAVI Fresh iPhone 17` (`97C29851-BACC-46AB-899E-774EC2B0287E`):
    `SAVI 1.0 (20)`, `SAVI Share 20`, `SAVI Test 1.0 (20)`, and `SAVI Test Share 20`.
  - Fixed Share Sheet setup practice flow so completion forces an immediate pending-share import refresh instead of waiting for relaunch.
  - Fixed image share previews in the share extension by falling back to the local image file path when the first-pass thumbnail field is missing.
  - Added subtle selected-folder color accents to the share extension preview card.
  - Clarified final Share Sheet setup copy: “one last install step,” pin SAVI in Share once, then save from apps in two taps.
  - `git diff --check` passed.
  - Signed Release archive succeeded:
    `/Users/guest1/Documents/SAVI-iOS/build/qa/archives/SAVI-20260507-171826-b20.xcarchive`.
  - Uploaded `SAVI 1.0 (20)` to App Store Connect/TestFlight; upload ended with `Uploaded SAVI` and `EXPORT SUCCEEDED`, now processing in App Store Connect.
  - Logs:
    - `/Users/guest1/Documents/SAVI-iOS/build/qa/logs/SAVI-archive-build20-final.log`
    - `/Users/guest1/Documents/SAVI-iOS/build/qa/logs/SAVI-export-upload-build20.log`

### 2026-05-07 14:57 CEST - Fast UI iteration guardrail

- Owner: current Codex chat
- Status: completed at 2026-05-07 15:00 CEST
- Intended files:
  - `/Users/guest1/Documents/SAVI-iOS/AGENTS.md`
  - `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`
- Notes:
  - Make future chats default to the fast one-simulator UI loop unless the user explicitly asks for a TestFlight/release gate.
- Result:
  - Added a Fast UI Iteration Rule to `AGENTS.md`: one current-size simulator, Debug `SAVI Test`, `scripts/savi-fast-dev-sim.sh`, and full Release/TestFlight gates only on explicit request.

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
