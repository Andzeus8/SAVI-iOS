# SAVI Preflight Automation

Use `scripts/savi-preflight.sh` as the normal local gate before backend,
social, App Store, TestFlight, or architecture-sensitive changes.

For GitHub CI, see `Docs/Architecture/Runbooks/GitHubActions.md`.

## Quick Gate

```bash
scripts/savi-preflight.sh
```

Runs:

- `git diff --check`,
- `scripts/savi-safety-scan.sh`,
- `scripts/savi-backend-readiness-check.py`,
- `scripts/savi-supabase-rls-check.py`,
- `scripts/savi-openapi-contract-check.py`,
- `scripts/savi-account-deletion-check.py`,
- `scripts/savi-moderation-readiness-check.py`,
- `scripts/savi-notification-readiness-check.py`,
- `scripts/savi-contract-fixtures-check.py`,
- `scripts/savi-analytics-contract-check.py`,
- `scripts/savi-privacy-inventory-check.py`,
- `scripts/savi-appstore-privacy-labels-check.py`,
- `scripts/savi-appstore-export-compliance-check.py`,
- `scripts/savi-privacy-manifest-check.py`,
- `scripts/savi-sdk-inventory-check.py`,
- `scripts/savi-sample-content-check.py`,
- `scripts/savi-public-site-check.py`,
- `scripts/savi-appstore-metadata-check.py`,
- `scripts/savi-appstore-age-rating-check.py`,
- `scripts/savi-testflight-ops-check.py`,
- `scripts/savi-crash-performance-check.py`,
- `scripts/savi-share-extension-qa-check.py`,
- `scripts/savi-archive-restore-check.py`,
- `scripts/savi-appstore-readiness-check.py`,
- `scripts/savi-docs-link-check.py`,
- public-site placeholder reminder.

The public-site reminder warns about TODO placeholders in legal/support pages.
Those TODOs should stay gone before App Store submission. The current drafts use
the beta support email until a public domain/support alias replaces it.

The public-site check also builds the static HTML site in a temporary directory
so the privacy/support/terms pages stay deployable without needing a domain
during local development.

The App Store privacy-label check keeps the current `No Data Collected` draft,
the conservative support-disclosure alternative, and the future
Supabase/PostHog/APNs/social update triggers aligned.

The App Store export-compliance check keeps both Info.plist export flags, the
current Apple/system encryption posture, third-party/custom crypto scan, and
founder/legal final-answer reminders aligned.

The App Store metadata check catches stale build numbers and verifies that the
copy-paste App Store Connect packet still contains the current app name,
subtitle, keyword budget, review notes, screenshot plan, and social-hidden
language.

The App Store age-rating check keeps the age questionnaire packet aligned with
the current private-save-first posture: no gambling, no contests, no
unrestricted browser, no live public social/UGC, no DMs/comments, neutral
health research framing, Kids-category caution, and future re-rating triggers.

The TestFlight operations check catches stale build references in tester
runbooks and confirms the internal group/tester troubleshooting flow is still
documented.

The crash/performance triage check keeps the iPhone 11/iOS 17, launch-crash,
scroll-jank, TestFlight-feedback, and privacy-safe diagnostics workflow
documented.

The Share Extension real-device QA check keeps the Safari/Photos/Files/video,
plain-text, PDF, generic-file, metadata fallback, app-group import, and
privacy-safe tester workflow documented.

The archive export/restore QA check keeps the Profile backup flow, preparing
state, iOS share/file sheet, compact JSON fallback, invalid-file handling,
fresh-install restore, Private Vault behavior, and no-publish-on-restore rules
documented.

## Release Gate

```bash
scripts/savi-preflight.sh --release-build
```

Adds the iOS Release generic iPhoneOS no-sign build.

## Full Local Gate

```bash
scripts/savi-preflight.sh --all-builds
```

Adds:

- iOS Release generic iPhoneOS no-sign build,
- `SAVI Mac` Debug build,
- `SAVI Mac` Release build.

Use the full gate before large backend/social/Finder Hub changes or before
handing off to a CTO/senior engineer. Use the quick gate during normal docs and
contract work.
