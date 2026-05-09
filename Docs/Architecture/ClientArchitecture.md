# SAVI Client Architecture

## Current Shape

The iOS app is native SwiftUI. The visible native launch path is:

`SAVIApp.swift -> ContentView -> NativeSaviRootView`

The app currently has a large core file. Future cleanup should split behavior
by responsibility without changing user-facing behavior in one risky jump.

## Target Layers

| Layer | Responsibility |
|---|---|
| Models | items, folders, tags, sources, metadata, account state |
| LocalData | persistence, sample seeding, import/export archives |
| ShareIngestion | share extension extraction, pending shares, normalization |
| Metadata | link preview, title/source/thumb enrichment, retry policy |
| FolderBrain | folder classifier, smart tags, confidence, learning |
| Sync | Supabase account/public-link sync and conflict handling |
| Analytics | typed event allowlist and privacy guard |
| Security | Private Vault, biometrics, release gates, entitlement checks |
| UI | Home, Search, Explore, Folders, Profile, onboarding, sheets |

## Service Boundary Rules

- UI calls app services, not Supabase/PostHog directly.
- External services are behind protocols so Release can use no-op clients and
  Debug can use mock clients.
- Share extension and app communicate through App Group data structures only.
- Feature gates live in one small release-gate layer, not scattered conditionals.
- Admin and Founder Hub code must not compile into the iPhone app target.

## Future Refactor Order

1. Extract pure models and value types.
2. Extract archive/local persistence.
3. Extract metadata and folder-classification services.
4. Extract analytics and social clients behind protocols.
5. Add Supabase sync after the local behavior is stable.

Each extraction should pass the existing iOS Release build before the next one.
