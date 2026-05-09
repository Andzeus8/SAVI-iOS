# SAVI Mac Companion Architecture

The current Xcode project is iPhone-only. Do not casually enable Catalyst on the production iPhone target.

## Recommended Path

1. Keep the current iPhone/TestFlight app stable.
2. Extract cross-platform pieces into shared Swift code:
   - item and folder models,
   - search/filtering,
   - metadata DTOs,
   - analytics event types,
   - social/sync service protocols.
3. Add a separate macOS SwiftUI target later:
   - bundle id: `com.altatecrd.savi.mac`,
   - app sandbox enabled,
   - network client entitlement enabled,
   - user-selected file import/export only.
4. Use Supabase for account/social/public-link sync.
5. Keep private files and Private Vault local/iCloud-only until a separate encrypted sync plan exists.

## Mac V1 Features

- sign in,
- view synced public/personal web links,
- search,
- folders,
- open links,
- friends feed when social is enabled,
- privacy-safe analytics using the same event allowlist.

## Not In Mac V1

- private vault file sync,
- automatic full file mirroring,
- contacts upload,
- public document publishing,
- moderation dashboard.
