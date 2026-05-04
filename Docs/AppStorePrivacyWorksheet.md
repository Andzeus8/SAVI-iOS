# SAVI App Store Privacy Worksheet

Last updated: 2026-05-03

This is a preparation worksheet for App Store Connect privacy labels. It is not
legal advice and should be checked against the final build, privacy policy, and
server configuration before submission.

## Release/TestFlight V1 Scope

Social Beta is disabled for Release/TestFlight. The app should not publish
friend links, public profiles, public folders, likes, or friend activity in this
beta. Debug builds may still expose those features for development.

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
- Metadata fetching may contact saved-link hosts to retrieve titles and
  thumbnails.
- Image search is user-triggered only and should be hidden if no proxy is
  configured.

## Submission Reminders

- Publish a Privacy Policy URL before external TestFlight review.
- Make Support URL or support email visible in App Store Connect.
- Confirm whether `ITSAppUsesNonExemptEncryption = NO` is appropriate before
  setting it or answering export compliance.
- Ensure `PrivacyInfo.xcprivacy` still covers any required reason APIs in the
  final linked app and extension.
