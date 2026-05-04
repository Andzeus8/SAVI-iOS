# SAVI Native iOS Guardrails

This repository is the active SAVI app. Use it for current SAVI work.

- Canonical project path: `/Users/guest1/Documents/SAVI-iOS`
- Xcode project: `/Users/guest1/Documents/SAVI-iOS/SAVI.xcodeproj`
- Main app target: `SAVI`
- Share extension target: `SAVIShareExtension`
- Simulator bundle id: `com.savi.app`

## Work Here For

- Native SwiftUI app UI and navigation
- Share extension save flow
- App Group pending-share import
- Metadata fetching and stale retry behavior
- Folder classification and learning
- Search, Explore, Home, Profile, Settings, previews, backup/import
- Face ID/private Folder behavior
- Apple Intelligence and local fallback logic
- App icon and iOS assets

## Do Not Confuse With Web Prototype

The old web folders are legacy prototypes:

- `/Users/guest1/Documents/SAVI`
- `/Users/guest1/Documents/SAVI `

Do not edit or sync those for normal iOS app work. `SAVI/Resources/index.html` is a frozen legacy migration/recovery asset only; it is not the visible app shell.

The native app launches from `SAVIApp.swift -> ContentView -> NativeSaviRootView`.
