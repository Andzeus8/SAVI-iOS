# SAVI Third-Party SDK Inventory

This is the living inventory for third-party SDK, package, and dependency
review. It exists because App Store privacy labels, SDK privacy manifests,
tracking rules, and security posture can change when a single SDK is added.

Source anchors:

- Apple third-party SDK requirements: https://developer.apple.com/support/third-party-SDK-requirements/
- Apple privacy manifest files: https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
- Apple user privacy and data use: https://developer.apple.com/app-store/user-privacy-and-data-use/

## Current Status

Current SAVI iOS/Mac repo state:

- no Swift Package Manager dependency checkout,
- no `Package.resolved`,
- no CocoaPods `Podfile`,
- no Carthage `Cartfile`,
- no checked-in `.xcframework` vendor SDK,
- no checked-in non-Apple `.framework` vendor SDK,
- no live Supabase iOS SDK,
- no live PostHog iOS SDK,
- no Sentry/Firebase/Amplitude/Mixpanel/RevenueCat/Google/Facebook SDK.

Current Swift imports are Apple/system frameworks only. Some source files include
strings like `Supabase`, `PostHog`, `Google Maps`, or `Facebook` as future
backend placeholders, sample/link metadata labels, or domain/source classifiers.
Those are not linked SDKs.

## Current Apple/System Frameworks Seen

The code currently imports Apple/system modules such as:

- `AppKit`
- `AuthenticationServices`
- `Charts`
- `CloudKit`
- `Darwin`
- `Foundation`
- `FoundationModels`
- `ImageIO`
- `LinkPresentation`
- `LocalAuthentication`
- `MobileCoreServices`
- `Network`
- `PhotosUI`
- `QuickLook`
- `SafariServices`
- `Security`
- `SwiftUI`
- `UIKit`
- `UniformTypeIdentifiers`
- `Vision`
- `WebKit`

These still need privacy review when their behavior changes, but they are not
third-party SDKs.

## Future SDK Review Gate

Before adding any SDK or package, update this file and review:

- App Store privacy labels,
- `Docs/Architecture/PrivacyDataInventory.md`,
- `Docs/Architecture/PrivacyManifestAudit.md`,
- `Docs/Architecture/AppStoreComplianceMatrix.md`,
- public privacy policy,
- tracking/ATT implications,
- whether the SDK is on Apple's third-party SDK requirements list,
- whether the SDK ships a valid privacy manifest,
- whether the SDK uses required-reason APIs,
- whether it collects diagnostics, analytics, identifiers, location, contacts,
  purchases, user content, or usage data,
- whether it enables autocapture, session replay, advertising, fingerprinting,
  or data-broker sharing by default.

## Planned SDKs / Services

| Service | Intended Use | Current Status | Rules Before Enabling |
|---|---|---:|---|
| Supabase | Accounts/social/public-link sync | Not linked as SDK | Use client-safe anon key only; service-role key server-side only |
| PostHog | Privacy-safe product analytics | Not linked as SDK | Manual allowlisted capture only; no autocapture/session replay |
| Sentry or crash tool | Crash/reliability triage | Not linked | Re-audit diagnostics privacy labels and private-content scrubbers |
| RevenueCat / StoreKit helper | Purchases later | Not linked | Re-audit purchases, identifiers, privacy policy, subscriptions |
| Image/search provider SDK | Image search later | Not linked | Prefer server/proxy or direct web API; avoid broad tracking SDKs |

## Prohibited Without Explicit Review

- advertising SDKs,
- data broker SDKs,
- session replay,
- autocapture analytics,
- contacts import SDKs,
- social graph scraping,
- private file upload SDKs,
- SDKs requiring service/admin keys in client apps,
- SDKs without clear privacy manifests/data practices.

## Local Check

Run:

```bash
scripts/savi-sdk-inventory-check.py
```

The check searches for package-manager files, checked-in vendor frameworks,
Swift package references, known third-party SDK imports, and non-Apple Swift
imports in app/shared/Mac source.
