# SAVI Native iOS Guardrails

This repository is the active SAVI app. Use it for current SAVI work.

- Canonical project path: `/Users/guest1/Documents/SAVI-iOS`
- Xcode project: `/Users/guest1/Documents/SAVI-iOS/SAVI.xcodeproj`
- Main app target: `SAVI`
- Share extension target: `SAVIShareExtension`
- Simulator bundle id: `com.altatecrd.savi`

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

## Concurrent Work Rule

Multiple Codex chats may work in this repo at the same time. Before editing:

- Run `git status --short`.
- Read `/Users/guest1/Documents/SAVI-iOS/Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md`.
- Add a short work-log entry listing the files you expect to touch.
- Avoid files another active chat has claimed unless the change is necessary.
- Never revert unrelated changes from another chat.
- After verification, update the work-log entry with status and test notes.
