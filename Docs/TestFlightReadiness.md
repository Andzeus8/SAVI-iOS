# SAVI TestFlight Readiness

Last updated: 2026-05-04

## Current Beta Posture

The first external TestFlight should ship as a private, local-first SAVI beta:

- Main app: `SAVI`
- Main bundle ID: `com.savi.app`
- Share extension bundle ID: `com.savi.app.ShareExtension`
- App Group: `group.com.savi.shared`
- iCloud container: `iCloud.com.savi.app`
- Build number: `2`
- Supported devices for first beta: iPhone only
- Supported phone orientation for first beta: portrait
- Release/TestFlight social posture: Social Beta disabled
- Debug/local social posture: Social Beta remains enabled for development

The Release build hides or blocks friend feeds, public profiles, public folder
publishing, sample friend Ava, friend activity widgets, public folder badges,
public CloudKit social writes, and debug-only tooling. It includes a removable
sample library on fresh install so testers can immediately try folders, Search,
Explore, Private Vault, and clear-sample behavior. Core SAVI stays enabled:
share extension, folders, search, Explore for personal content, Face ID locks,
metadata, Apple Intelligence fallback, and archive export/import.

## Build Channels

SAVI uses one source tree with two installed channels:

- `SAVI` is the Release/TestFlight channel. It uses `com.savi.app`, shows as
  `SAVI`, hides Social Beta, hides debug/demo tooling, and is the build to
  archive/upload to App Store Connect.
- `SAVI Test` is the Debug/development channel. It uses
  `com.altatecrd.savi.personaldebug`, shows as `SAVI Test`, keeps Social Beta
  and debug/demo tooling visible, and is the app to use when building unfinished
  social features.

Do not add a third `SAVI Pilot` app yet. Add one only if we later need an
internal QA mirror that behaves like TestFlight but installs alongside both
existing channels.

## Apple-Side Checklist

Create or verify these in Apple Developer and App Store Connect:

- App ID: `com.savi.app`
- Share extension App ID: `com.savi.app.ShareExtension`
- App Group: `group.com.savi.shared`
- iCloud container: `iCloud.com.savi.app`
- App Store Connect app record for `SAVI`
- Production signing/provisioning for the app and extension
- CloudKit private-container readiness if optional iCloud backup is included

You still need to provide:

- Privacy Policy URL
- Support URL or support email
- Beta feedback email
- App category
- Age rating
- Screenshots
- Beta description
- What to Test notes
- Export compliance answers

SAVI appears to use standard Apple/HTTPS/CloudKit encryption only, but export
compliance is a legal declaration. Do not set or submit the final export answer
until you confirm no custom/non-exempt encryption is used. The app and share
extension Info.plists include `ITSAppUsesNonExemptEncryption = NO` to match the
current code posture; confirm this in App Store Connect before upload.

## Hardening Applied For Build 2

- Release `SAVI` resolves to `com.savi.app`; Debug `SAVI Test` resolves to
  `com.altatecrd.savi.personaldebug`.
- Release Social Beta is hidden/blocked; Debug keeps it available for internal
  development.
- Release is iPhone-only and portrait-only for the first external beta, matching
  the UI surfaces actually designed and QA'd.
- The removable sample library is enabled in Release so external testers do not
  start from an empty app.
- Privacy manifests are bundled for both the app and share extension.
- Export-compliance plist key is present for both the app and share extension.
- `generate_project.py` now preserves the current Team ID, build number,
  iPhone-only target family, and sample-library build setting if the Xcode
  project is regenerated.

## Suggested TestFlight Review Notes

Social Beta is disabled in this build. A removable sample library is included
on first launch to demonstrate folders, Search, Explore, Private Vault, dates,
tags, file types, and the `Clear sample saves` control. Testers can save links,
files, images, PDFs, notes, and screenshots through the iOS Share Sheet,
organize saves into folders, search/refine their library, browse personal saved
links in Explore, lock private folders with Face ID/passcode, and export or
restore a full local archive. Public friend feeds and public sharing controls
are hidden for this beta while moderation, reporting, and terms are prepared.

## Production Build Flow

1. Build scheme `SAVI`.
2. Configuration `Release`.
3. Destination `Any iOS Device`.
4. Confirm Release resolves to `com.savi.app`, not `com.altatecrd.savi.personaldebug`.
5. Confirm `SAVIShareExtension` embeds as `com.savi.app.ShareExtension`.
6. Archive from Xcode.
7. Upload to App Store Connect.
8. Add internal testers first.
9. Submit the first external group to TestFlight App Review.

## Verification Checklist

- Fresh install: onboarding, Home sample library, Search, Explore, Folders, Profile.
- Share extension: URL, YouTube, TikTok, Instagram, X/Twitter, text, image, PDF, generic file.
- Metadata/AI: save remains instant if metadata or Apple Intelligence times out.
- Privacy: locked folders and Private Vault stay hidden until Face ID/passcode.
- Archive: export warns about private content, restore does not publish anything.
- Offline: app remains usable without network.
- Large library: Home/Search scroll smoothly.
- Light/dark: no unreadable cards, folder names, timeline text, or sheets.

## References

- [TestFlight overview](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/)
- [Invite external testers](https://developer.apple.com/help/app-store-connect/test-a-beta-version/invite-external-testers)
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [App privacy details](https://developer.apple.com/app-store/app-privacy-details/)
- [Privacy manifests](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files)
- [Export compliance](https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance/)
- [Account deletion guidance](https://developer.apple.com/support/offering-account-deletion-in-your-app/)
