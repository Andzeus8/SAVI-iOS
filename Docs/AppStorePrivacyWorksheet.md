# SAVI App Store Privacy Worksheet

Last updated: 2026-05-09

This is a preparation worksheet for App Store Connect privacy labels. It is not
legal advice and should be checked against the final build, privacy policy, and
server configuration before submission.

Use the current answer packet first:

- `Docs/Architecture/Runbooks/AppStorePrivacyLabels.md`
- `scripts/savi-appstore-privacy-labels-check.py`

## Release/TestFlight V1 Scope

Social Beta is disabled for Release/TestFlight. The app should not publish
friend links, public profiles, public folders, likes, or friend activity in this
beta. Debug builds may still expose those features for development.

Current private-save-first assumptions:

- No required SAVI account.
- No live Supabase production collection.
- No live PostHog production analytics.
- No APNs/device-token collection.
- No public social publishing.
- No live SAVI metadata proxy.
- No third-party SDKs in the current native source.

## Current Answer Draft

If the exact submitted build still matches the current scope above, the working
App Store privacy-label draft is `No Data Collected` for SAVI's app privacy
label, with `Tracking = No`.

This draft depends on local-only saves staying local, Help & Feedback remaining
user-initiated, no automatic log/saved-content attachment, and no live
Supabase/PostHog/APNs/social/metadata-proxy paths in Release.

Conservative support disclosure: if founder/legal decides the user-initiated
feedback email should be listed, disclose Contact Info / Email Address for App
Functionality or customer support, linked to the user, not used for tracking.

## Data SAVI Handles

- User content: saved URLs, titles, notes, descriptions, tags, folder names,
  thumbnails, images, PDFs, screenshots, and files.
- Local organization data: folder order, folder colors/icons, locked/private
  folder flags, search prefs, Home widgets, and folder-learning signals.
- Optional account/iCloud state: Apple ID credential status and iCloud/CloudKit
  availability when the user checks or uses iCloud features.
- Network metadata: SAVI may fetch metadata/thumbnails for URLs the user saves.
- Optional image search: user-triggered folder/item artwork search may send the
  typed search query to the configured image-search proxy/provider.
- Diagnostics: TestFlight/Apple crash and feedback tooling may collect system
  diagnostics outside SAVI app code.

## Data Not Intended For Release/TestFlight V1

- No active public friend feed.
- No public profile publishing.
- No public folder publishing.
- No public CloudKit social writes.
- No automatic upload of saved files, PDFs, images, notes, or private folder
  contents to a public service.
- No analytics SDK is currently documented in this native source.

## Likely Privacy Label Areas To Review

- User Content: saved files, links, notes, images, PDFs, and thumbnails.
- Identifiers: only if Sign in with Apple or iCloud/account identity is active
  in the submitted build.
- Search History or Browsing History: only if saved URLs/searches are collected
  off-device beyond user-triggered metadata/image requests.
- Diagnostics: Apple/TestFlight diagnostics may apply depending on App Store
  Connect settings.

## User-Facing Copy To Keep Accurate

- Full archives can include private/locked content and should be stored safely.
- Optional iCloud backup is private to the user's iCloud container.
- Social Beta is off in the first external beta.
- Help & Feedback sends tester-written email to `1080solutionsA@gmail.com`; SAVI does
  not attach logs or saved content automatically.
- Metadata fetching may contact saved-link hosts to retrieve titles and
  thumbnails.
- Image search is user-triggered only and should be hidden if no proxy is
  configured.

## Submission Reminders

- Publish a Privacy Policy URL before external TestFlight review.
- Use `Docs/Architecture/Runbooks/AppStorePrivacyLabels.md` when entering App
  Store Connect answers.
- Make Support URL or support email visible in App Store Connect. Use
  `1080solutionsA@gmail.com` for the first beta unless a separate support alias is
  created.
- Confirm whether `ITSAppUsesNonExemptEncryption = NO` is appropriate before
  setting it or answering export compliance. Use
  `Docs/Architecture/Runbooks/AppStoreExportCompliance.md` and
  `scripts/savi-appstore-export-compliance-check.py`.
- Ensure `PrivacyInfo.xcprivacy` still covers any required reason APIs in the
  final linked app and extension. Current audit:
  `Docs/Architecture/PrivacyManifestAudit.md`.
