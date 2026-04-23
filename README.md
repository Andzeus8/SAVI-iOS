# SAVI iOS

Native iOS app and Share Extension for SAVI.

## What Is Included

- `SAVI` iOS app target
- `SAVIShareExtension` Share Extension target
- App Group setup for `group.com.savi.shared`
- Bundled copy of the existing SAVI `index.html`
- Native share handoff through `pending_shares/` in the shared container
- Sync script so the native app always bundles the latest web app

## Project Layout

- `SAVI/`
  App target sources, plist, entitlements, assets, bundled web app resources
- `SAVIShareExtension/`
  Share Extension source, plist, entitlements
- `Shared/`
  App Group constants, pending share model, and shared storage helpers
- `scripts/`
  Utilities for syncing the web app into the native bundle
- `SAVI.xcodeproj/`
  Generated Xcode project

## Source Of Truth

SAVI now lives in two separate codebases:

- Web app source of truth:
  `/Users/guest1/Documents/SAVI /index.html`
- Native iOS source of truth:
  `/Users/guest1/Documents/SAVI-iOS/`

Rule of thumb:

- If you are changing the SAVI library UI, item cards, item detail, folders, or general app behavior inside the web experience, edit the web repo first.
- If you are changing the Share Extension, App Groups, native import pipeline, or any Swift code, edit this repo.
- The iOS app bundles a copy of the web app. That bundled copy should not be hand-edited unless you are debugging a sync problem.

## Build Notes

1. Open `/Users/guest1/Documents/SAVI-iOS/SAVI.xcodeproj` in Xcode.
2. Set your Apple Developer team under Signing for both targets if Xcode asks.
3. Confirm the App Group capability is enabled for both targets with:
   `group.com.savi.shared`
4. Build and run the `SAVI` scheme in the iOS Simulator.
5. Build the Share Extension as part of the app target, then test sharing from Safari, Photos, or Files.

## Sync Workflow

Before running the iOS app, sync the latest web app into the native bundle:

```bash
/Users/guest1/Documents/SAVI-iOS/scripts/sync_web_bundle.sh
```

That script copies:

- from `/Users/guest1/Documents/SAVI /index.html`
- to `/Users/guest1/Documents/SAVI-iOS/SAVI/Resources/index.html`

The Xcode project is also configured to run this sync automatically during the `SAVI` target build, so local builds stay current.

## Recommended Daily Workflow

### When working on the web app

1. Edit `/Users/guest1/Documents/SAVI /index.html`
2. Commit/push the web repo
3. Run `scripts/sync_web_bundle.sh`
4. Build/run the iOS app in Xcode

### When working on the native app

1. Edit Swift/Xcode files in `/Users/guest1/Documents/SAVI-iOS`
2. Commit/push this repo
3. Rebuild in Xcode

### When a feature touches both

1. Update the web app
2. Sync the bundle into iOS
3. Update native bridge/share-extension code if needed
4. Commit each repo separately

## How Sharing Works

- The Share Extension accepts URLs, text, images, PDFs, and general files.
- Each shared item is written as JSON into the App Group container under:
  `pending_shares/`
- The main app checks for pending shares whenever the web view finishes loading and whenever the app returns to the foreground.
- Imported shares are merged into the existing SAVI web app local storage (`savi_v1`) from native code.

## Important Note

The native app now compiles locally in Xcode and from the command line for the iOS Simulator. The remaining Apple-specific setup is choosing your signing team in Xcode for device/TestFlight builds.
