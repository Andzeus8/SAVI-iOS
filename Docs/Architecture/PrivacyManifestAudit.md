# SAVI Privacy Manifest Audit

This audit tracks Apple's privacy manifest / required-reason API posture for the
native iOS app and share extension.

Source anchors:

- Apple required-reason APIs: https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api
- Apple privacy manifest files: https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
- Apple TN3183: https://developer.apple.com/documentation/technotes/tn3183-adding-required-reason-api-entries-to-your-privacy-manifest

## Current Manifests

| Target | Manifest | Required-Reason API Categories |
|---|---|---|
| `SAVI` | `SAVI/PrivacyInfo.xcprivacy` | `NSPrivacyAccessedAPICategoryFileTimestamp` / `C617.1`; `NSPrivacyAccessedAPICategoryUserDefaults` / `CA92.1` |
| `SAVIShareExtension` | `SAVIShareExtension/PrivacyInfo.xcprivacy` | `NSPrivacyAccessedAPICategoryFileTimestamp` / `C617.1` |

Both manifests must keep:

- `NSPrivacyTracking = false`,
- `NSPrivacyTrackingDomains = []`.

## Why These Reasons Exist

- `NSPrivacyAccessedAPICategoryFileTimestamp` with `C617.1` covers access to
  file timestamps/metadata inside the app or app group container, used by SAVI's
  local archive, app group, pending share, and file import/export paths.
- `NSPrivacyAccessedAPICategoryUserDefaults` with `CA92.1` covers app-only
  `UserDefaults` access for preferences and QA overrides in the main app.

## Current Source Signals

- Main app source uses `UserDefaults` in `SAVI/Core/SaviCore.swift`.
- Shared/app-group and share extension source use file metadata APIs such as
  `contentModificationDateKey` and app container/app group `FileManager` paths.
- No current source signal requires declaring disk-space, system-boot-time, or
  active-keyboard required-reason categories.

## Update Triggers

Re-audit the manifests when adding:

- new persistence APIs,
- app group file metadata changes,
- disk-space checks,
- system boot time checks,
- active keyboard checks,
- third-party SDKs,
- analytics/crash SDKs,
- user-facing Mac distribution,
- App Intents/widgets/extensions,
- Android backend does not affect this file, but new iOS SDKs do.

## Local Check

Run:

```bash
scripts/savi-privacy-manifest-check.py
```

The check parses both source manifests, verifies required reason categories,
confirms tracking is off, verifies the manifests are included in the Xcode
project, and checks current source signals against the manifest contents.
