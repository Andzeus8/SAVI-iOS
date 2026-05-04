# SAVI Production Readiness

This is the release gate for the native iOS app. The goal is to make production checks repeatable instead of relying on a single simulator run.

## Visual QA Matrix

Run:

```bash
Tools/savi-production-ui-qa.sh
```

Default coverage:

- iPhone SE 3rd generation: smallest supported iPhone shape.
- iPhone 17: normal iPhone.
- iPhone 17 Pro Max: largest common iPhone.
- iPhone Air: thin/tall modern iPhone shape.
- Light and dark appearance.
- Home, Search, Explore, Folders, Profile.

Screenshots are written to:

```text
build/production-ui-qa/<timestamp>/
```

Pass criteria:

- No clipped titles, buttons, chips, or folder names.
- Bottom navigation never covers important list content.
- Cards, folder tiles, and mosaics keep stable spacing.
- Primary action is reachable and obvious on every sheet.
- Light mode and dark mode both have readable contrast.
- Long item titles, URLs, source names, tags, and folder names truncate cleanly.
- The app still feels like SAVI: colorful and friendly, but not noisy.

## Accessibility Gate

- Icon-only buttons have accessibility labels.
- Tap targets are at least 44 pt.
- Dynamic Type should not cause broken layout on cards, sheets, bottom tabs, or folder grids.
- Locked/private folders must be understandable without exposing protected content.
- Color is never the only signal for public, locked, active, destructive, or failed states.

## Data Safety Gate

- Share extension saves immediately without waiting on metadata or Apple Intelligence.
- Apple Intelligence is optional; local rules work when unavailable or timed out.
- Manual folder corrections train local learning and block later AI folder overrides.
- Private Vault and locked folders stay hidden until unlocked.
- Full archive export warns that private/locked content may be included.
- Restore/import does not publish social or public data without explicit user action.

## App Store Gate

- Build Release for `SAVI` and `SAVIShareExtension`.
- Verify signing, App Group, share extension, privacy manifest, and entitlements for the intended bundle id.
- Confirm no debug-only personal bundle id is used for the App Store build.
- For the first external beta, keep Release iPhone-only and portrait-only until
  iPad and landscape have their own QA pass.
- Confirm any CloudKit/iCloud capability is enabled only for the build profile that supports it.
- Confirm no API keys are bundled in the app.
- Confirm privacy labels match local storage, CloudKit/social sync, image search proxy, metadata fetching, and analytics status.
- Confirm the App Store Connect export-compliance answer matches
  `ITSAppUsesNonExemptEncryption = NO` in the app and share extension.

## Share Extension Gate

Test from real share sheets where possible:

- URL link.
- YouTube/TikTok/Instagram/X link.
- Plain text.
- Image.
- PDF.
- Generic file.

Pass criteria:

- Save button remains reachable.
- Manual folder selection is quick.
- Metadata and AI never trap the user.
- Pending share imports into the main app on foreground.

## Performance Gate

- Cold launch feels immediate on a fresh install.
- Home and Search scroll without visible hitching on seeded/demo data.
- Explore mosaic loads without overlapping cards.
- Metadata and thumbnail fetches are capped and retry safely.
- Build time remains tolerable by keeping huge SwiftUI views split into smaller components.

## Release Decision

SAVI is production-ready only when:

- The visual QA matrix has been reviewed.
- Debug/personal signing has been replaced with production signing.
- Share extension has passed real-device tests.
- Backup/export/restore has passed at least one fresh-install restore.
- Privacy/App Store capability review is complete.

## First External TestFlight Posture

- Use two build channels from one source tree:
  - `SAVI` / `com.savi.app` / Release is the TestFlight and App Store channel.
  - `SAVI Test` / `com.altatecrd.savi.personaldebug` / Debug is the internal
    development channel.
- Ship the first external beta with Social Beta disabled in Release.
- Keep friend feeds, public profiles, public folders, public sharing toggles,
  sample friend data, and public CloudKit social writes out of TestFlight until
  moderation, reporting, terms, privacy policy, and review notes are ready.
- Include a removable sample library in the first TestFlight build so testers
  can understand folders, Search, Explore, and Private Vault immediately. Keep
  debug-only tooling out of Release/TestFlight builds.
- Keep the app's private core enabled: share extension, folders, Search,
  personal Explore, locked folders, metadata, Apple Intelligence fallback, and
  full archive export/import.
- Treat Debug / `SAVI Test` as the only channel where Social may remain visible
  for development.
- Do not add a third `SAVI Pilot` app unless a separate internal QA mirror is
  needed later.
