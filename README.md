# SAVI iOS

This is the active SAVI product codebase.

## Canonical Project

- Native iOS app: `/Users/guest1/Documents/SAVI-iOS`
- Xcode project: `/Users/guest1/Documents/SAVI-iOS/SAVI.xcodeproj`
- App target: `SAVI`
- Share Extension target: `SAVIShareExtension`
- App Group: `group.com.savi.shared`

All current product work should happen here unless a request explicitly says to edit the old web prototype.

## Current Architecture

- `SAVI/ContentView.swift`
  Native SwiftUI app, storage, navigation, search, Explore, Folders, backup/import, previews, Face ID folder locks, metadata enrichment, Apple Intelligence/fallback refinement, and migration host.
- `SAVIShareExtension/`
  Native share extension UI and fast-save import pipeline.
- `Shared/AppGroupSupport.swift`
  App Group models, pending-share contract, folder classifier, learning signals, and folder decision audit.
- `SAVI/Resources/index.html`
  Frozen legacy web snapshot used only for hidden one-time migration/recovery. It is not the visible app UI.

## Important Guardrail

Do not sync or rebuild from `/Users/guest1/Documents/SAVI /index.html` during normal iOS work. The old web app is a legacy prototype now. The Xcode build no longer runs the web sync script automatically.

If a task involves SAVI app UI, metadata, search, Folders, sharing, folder decisions, Apple Intelligence, Face ID, Explore, thumbnails, previews, profile/settings, backup/import, or simulator testing, edit the native iOS files in this repo.

## Build And Run

Use the `SAVI` scheme with the iOS Simulator.

```bash
xcodebuild \
  -project /Users/guest1/Documents/SAVI-iOS/SAVI.xcodeproj \
  -scheme SAVI \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=SAVI Fresh iPhone 17'
```

The share extension is embedded by the app target.

## Legacy Web Notes

The old web folders may still exist for reference:

- `/Users/guest1/Documents/SAVI`
- `/Users/guest1/Documents/SAVI `

They are not the active production app. Only touch them when a request explicitly asks for the web prototype.
