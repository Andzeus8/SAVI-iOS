# Android Readiness

SAVI should stay iOS-native now and become Android-ready through clean backend
contracts, not by forcing a cross-platform UI rewrite.

## Recommended Path

- Keep iOS SwiftUI.
- Build Android later with native Kotlin and Jetpack Compose.
- Share backend contracts, not UI code.
- Use OpenAPI/JSON Schema before Android implementation begins.
- Keep naming stable across platforms.

## What Must Stay Portable

- item type names,
- folder IDs,
- tag format,
- public/private eligibility rules,
- analytics event names,
- safe analytics property names,
- Supabase table/field names,
- sync conflict rules,
- backend error codes.

## Avoid Platform Traps

- Do not make Supabase rows depend on Swift enum raw values that Android cannot
  easily mirror.
- Do not store Apple-only identifiers as global account IDs.
- Do not put folder classification rules only inside SwiftUI views.
- Do not make social or analytics depend on CloudKit.
- Do not make Private Vault sync rely on platform-specific behavior without a
  documented fallback.

## Future Android Modules

- `data`: Supabase client, local database, repositories.
- `domain`: item/folder/search/sync rules.
- `ui`: Compose screens for Home, Search, Folders, Explore, Profile.
- `share`: Android share target/intent receiver.
- `analytics`: same event allowlist and privacy guard.
