# SAVI Release Governance

Use this with:

- `Docs/Architecture/AppStoreComplianceMatrix.md`
- `Docs/Architecture/Runbooks/AppStoreSubmissionPacket.md`
- `Docs/Architecture/Runbooks/AppStoreAgeRating.md`
- `Docs/Architecture/Runbooks/AppStoreExportCompliance.md`
- `Docs/ProductionReadiness.md`
- `Docs/TestFlightReadiness.md`
- `Docs/Architecture/Runbooks/PreflightAutomation.md`
- `Docs/Architecture/Runbooks/ShareExtensionRealDeviceQA.md`
- `Docs/Architecture/Runbooks/ArchiveExportRestoreQA.md`
- `scripts/savi-preflight.sh`
- `scripts/savi-safety-scan.sh`
- `scripts/savi-backend-readiness-check.py`
- `scripts/savi-appstore-readiness-check.py`
- `scripts/savi-appstore-age-rating-check.py`
- `scripts/savi-appstore-export-compliance-check.py`
- `scripts/savi-share-extension-qa-check.py`
- `scripts/savi-archive-restore-check.py`

## Before TestFlight Upload

- `git diff --check`
- `scripts/savi-preflight.sh --release-build`
- `scripts/savi-appstore-readiness-check.py`
- `scripts/savi-appstore-age-rating-check.py`
- `scripts/savi-appstore-export-compliance-check.py`
- `scripts/savi-share-extension-qa-check.py`
- `scripts/savi-archive-restore-check.py`
- iOS Release no-sign build.
- Share extension smoke test.
- Share extension real-device QA for Safari, Photos, Files, video/social link,
  plain text, metadata fallback, and main-app import.
- Archive export/restore QA for full ZIP archive, compact JSON backup, cancel
  states, invalid-file handling, and fresh-install restore.
- Home/Search/Explore/Profile smoke test.
- iPhone 11 or legacy-device spot check when performance code changes.
- Confirm Release social gate is off.
- Confirm CloudKit/iCloud backup is hidden or no-op unless verified.
- Confirm sample library loads and can be cleared.
- Confirm age-rating answers still match the submitted sample, health,
  browser/unrestricted web access, and social/UGC posture.
- Confirm export-compliance answers still match app/share-extension Info.plist
  keys and the submitted binary's encryption behavior.

## Before External Social

- Confirm `Docs/Architecture/SocialV1ImplementationPlan.md` Phase 5 is complete.
- Run `scripts/savi-preflight.sh --all-builds`.
- Complete social safety checklist.
- Test RLS policies.
- Test report/block/delete.
- Test account deletion path.
- Run `scripts/savi-account-deletion-check.py`.
- Update privacy policy and App Store privacy labels.
- Prepare Apple review notes and test account.

## Before Analytics Goes Live

- Confirm `Docs/Architecture/PrivacyDataInventory.md` is updated.
- Confirm opt-in/copy.
- Confirm manual event allowlist only.
- Confirm no private content properties.
- Confirm PostHog project token is client-safe.
- Confirm autocapture/session replay are off.
- Confirm dashboards use safe domains/public URLs only.

## Before Push Notifications Go Live

- Confirm `Docs/Backend/NotificationRunbook.md` is complete.
- Run `scripts/savi-notification-readiness-check.py`.
- Confirm notification permission is not requested on first launch.
- Confirm in-app notification settings exist.
- Confirm APNs keys live only in protected backend infrastructure.
- Confirm logout/account deletion disables device-token records.
- Confirm notification text is privacy-safe on the lock screen.
- Update privacy policy and App Store privacy labels.

## Before App Store Privacy Answers Change

- Update `Docs/Architecture/PrivacyDataInventory.md`.
- Update `Docs/Architecture/ThirdPartySDKInventory.md` if dependencies changed.
- Run `scripts/savi-privacy-inventory-check.py`.
- Run `scripts/savi-sdk-inventory-check.py`.
- Reconcile the exact submitted build with App Store Connect privacy labels.
- Confirm third-party SDK data practices are documented.

## Before Age Rating Answers Change

- Update `Docs/Architecture/Runbooks/AppStoreAgeRating.md`.
- Run `scripts/savi-appstore-age-rating-check.py`.
- Reconcile sample content, health research framing, meme/rabbit-hole links,
  browser/unrestricted web access behavior, social/UGC visibility, DMs/comments,
  Kids-category posture, contests, gambling, ads, and App Review notes.
- Answer App Store Connect from the submitted build's actual behavior, not the
  roadmap.

## Before Export Compliance Answers Change

- Update `Docs/Architecture/Runbooks/AppStoreExportCompliance.md`.
- Run `scripts/savi-appstore-export-compliance-check.py`.
- Run `scripts/savi-sdk-inventory-check.py`.
- Reconcile the app and share-extension `ITSAppUsesNonExemptEncryption` keys,
  custom/proprietary crypto usage, linked third-party SDKs, network/security
  code, optional France documentation needs, and the exact submitted binary.
- Founder/legal must answer App Store Connect truthfully; do not use repo docs
  as legal advice.

## Before Android

- Freeze API contract v1.
- Add OpenAPI/JSON Schema.
- Add backend contract tests.
- Add event contract tests.
- Verify folder IDs and item types are platform-neutral.
