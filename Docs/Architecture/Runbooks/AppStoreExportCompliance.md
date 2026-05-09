# SAVI App Store Export Compliance Packet

Use this packet before answering App Store Connect export-compliance questions
for the current SAVI iOS submission. It is not legal advice. The founder/legal
owner is responsible for the final declaration in App Store Connect and for
confirming the exact submitted build.

Run this checker after changing encryption, networking, security frameworks,
SDKs, backend clients, app targets, or App Store submission docs:

```bash
scripts/savi-appstore-export-compliance-check.py
```

## Source Anchors

- Apple: [Overview of export compliance](https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance/)
- Apple: [Export compliance documentation for encryption](https://developer.apple.com/help/app-store-connect/reference/app-information/export-compliance-documentation-for-encryption/)
- Apple: [`ITSAppUsesNonExemptEncryption`](https://developer.apple.com/documentation/bundleresources/information-property-list/itsappusesnonexemptencryption)

Apple says apps that use, access, contain, implement, or incorporate encryption
need an export-compliance determination in App Store Connect. Apple also says
`ITSAppUsesNonExemptEncryption = NO` indicates the app either uses no
encryption or only encryption that is exempt from export compliance
requirements. If an app uses non-exempt encryption, the answer and documentation
requirements can change.

## Current Submitted-Build Facts

Scope for this packet:

- Release iPhone app: `SAVI` / `com.altatecrd.savi`.
- Share extension: `com.altatecrd.savi.ShareExtension`.
- Current project/latest uploaded build in docs: `1.0 (34)`.
- This packet does not declare anything for future Android, live Supabase,
  live PostHog, public social, or a distributed Mac Founder Hub.

Current plist posture:

- `SAVI/Info.plist` has `ITSAppUsesNonExemptEncryption = NO`.
- `SAVIShareExtension/Info.plist` has `ITSAppUsesNonExemptEncryption = NO`.
- No `ITSEncryptionExportComplianceCode` is expected while the answer remains
  non-exempt-encryption false.

Current code posture:

- SAVI appears to rely on Apple/system services and normal network transport:
  `URLSession` over HTTPS/TLS, `LocalAuthentication`, `Security`/Keychain-style
  platform APIs, WebKit/Safari/LinkPresentation, and hidden/no-op CloudKit
  backup posture in Release.
- The current repo has no linked third-party SDKs, no Swift Package Manager
  dependencies, and no known bundled OpenSSL/BoringSSL/libsodium/CryptoSwift
  framework.
- The current app posture is no custom/proprietary encryption in the submitted
  app/share-extension targets.
- The current Swift code should not import or implement custom/proprietary
  encryption algorithms, `CryptoKit`, `CommonCrypto`, OpenSSL, libsodium,
  `CCCrypt`, manual AES/RSA/ChaCha/ECDSA primitives, or similar crypto code
  without triggering a fresh review.

## Recommended Current Posture

Founder/legal final answer required:

```text
The current iOS app and share extension appear to use only Apple operating
system encryption and standard HTTPS/TLS transport, with
ITSAppUsesNonExemptEncryption set to NO in both Info.plists. No custom,
proprietary, or bundled third-party encryption implementation is intentionally
included in the submitted build.
```

Operational meaning:

- The existing plist key is consistent with the current technical posture.
- App Store Connect export compliance still must be answered truthfully by the
  founder/legal owner.
- Do not claim a final legal exemption from this repo packet alone.
- If Apple asks for more detail, answer based on the exact binary, not roadmap
  features or future backend plans.

## Documentation Decision Guide

Apple's export documentation table says:

| Encryption In Use | Current SAVI Stance | Documentation Risk |
|---|---|---|
| Encryption limited to Apple operating system | Current expected posture | Apple says no documentation required in App Store Connect. |
| Industry-standard algorithm not provided within Apple OS | Not expected in current build | May require a French encryption declaration in App Store Connect if distributing in France. |
| Proprietary/non-standard encryption algorithms | Not allowed without explicit review | May require US Commodity Classification Automated Tracking System (CCATS) and French encryption declaration. |

This packet intentionally keeps the current build in the first row. If code or
SDKs move SAVI into a later row, stop and reassess before uploading.

## Future Changes That Trigger Re-review

Re-run this packet and update the App Store Connect answer if any of these
ship in Release, external TestFlight, or a distributed Mac app:

- Add `CryptoKit`, `CommonCrypto`, OpenSSL, BoringSSL, libsodium, CryptoSwift,
  custom AES/RSA/ChaCha/ECDSA code, password-based encryption, or proprietary
  cryptographic protocols.
- Add an SDK that performs encryption outside Apple operating system APIs.
- Enable end-to-end encrypted private file sync, encrypted vault sync, encrypted
  cross-platform backups, or custom encrypted archives.
- Enable Supabase/PostHog/other backend SDKs that introduce non-Apple
  encryption implementations.
- Add VPN, tunneling, proxy, secure messaging, secure file transfer,
  certificate pinning with custom crypto, crypto wallets, blockchain signing, or
  similar security product features.
- Distribute the Mac Founder Hub or any admin tool through App Store channels.
- Change either `Info.plist` export-compliance key or add
  `ITSEncryptionExportComplianceCode`.

## Final Founder Checklist

- Run `scripts/savi-appstore-export-compliance-check.py`.
- Run `scripts/savi-sdk-inventory-check.py`.
- Confirm app and share extension plists still say
  `ITSAppUsesNonExemptEncryption = NO`.
- Confirm the submitted binary has no newly linked crypto SDKs or custom crypto
  code.
- Confirm whether optional France distribution changes documentation needs.
- Answer App Store Connect export compliance from the exact submitted build.
- Save final Apple export-compliance confirmation privately if desired. Do not
  commit private legal filings, CCATS numbers, or Apple account screenshots with
  personal account information.
