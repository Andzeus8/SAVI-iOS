# SAVI Account Deletion Runbook

This runbook is required before SAVI enables accounts, sync, or external social
features. It keeps Apple's account-deletion requirement, Supabase data cleanup,
Sign in with Apple revocation, and local-first SAVI behavior in one place.

## Current Release

The current private-save TestFlight release does not require an account. Saved
items are local to the device unless the user exports an archive. Users can
delete local saves in the app or remove the app to delete local app data from
the device.

Release/TestFlight should keep account deletion marked as not needed until
accounts are actually enabled.

## Future Account Contract

When accounts launch, SAVI must expose an in-app account deletion entry and the
backend must support:

- `DELETE /me/account`,
- Sign in with Apple credential revocation where applicable,
- deletion/cascade of account-owned social rows,
- deletion or invalidation of backend sessions/device tokens,
- user-safe completion messaging,
- support contact fallback from the public data-deletion page.

Private on-device library content remains controlled by the local app and local
archive path. The backend must not promise to delete data it never had.

## Server-Side Sequence

The protected backend/account path should:

1. Authenticate the current user.
2. Confirm the user is deleting their own account.
3. Revoke Sign in with Apple credentials where applicable.
4. Delete or disable device-token records for notifications.
5. Delete the Supabase auth user through a protected server/admin path.
6. Let `on delete cascade` remove account-owned social rows.
7. Record a minimal deletion audit event with user id, timestamp, request id,
   and completion status, without private content.
8. Return a user-safe success or queued/completion response.

Service-role keys stay server-side. The iPhone app, share extension, and
user-facing Mac companion must never receive Supabase service-role keys or
admin deletion credentials.

## Data Coverage

| Data | Deletion Behavior |
|---|---|
| Profile and username | Deleted by `profiles.id references auth.users(id) on delete cascade` |
| Follow graph | Deleted by `follows.follower_id` / `follows.followee_id` cascades |
| Public links | Deleted by `public_links.owner_id` cascade |
| Likes | Deleted by `link_likes.user_id` and public-link cascades |
| Reports | Reporter/target references cascade where legally appropriate |
| Blocks | Deleted by `blocks.blocker_id` / `blocks.blocked_id` cascades |
| Notification device tokens | Deleted/invalidated by backend account deletion path |
| Public web-link thumbnails/metadata | Deleted with the public link record unless separately cached by policy |
| PostHog analytics | De-identify/delete person profile when configured; aggregate metrics may remain |
| Admin moderation audit log | Retain minimal operational audit rows when legally/support-required |
| Local private library | Deleted locally by app controls/app removal; not backend-owned |
| Private Vault | Never public/social; local/private-backup-only until separate encrypted sync exists |

## App Requirements

Before accounts launch externally:

- Profile/Settings must include a clear account deletion entry.
- The deletion confirmation must explain local library versus account data.
- The flow must require explicit confirmation.
- The user must see success/failure state.
- Failed deletion must provide support fallback.
- Sign in with Apple token revocation must be tested.
- Social/public publishing must remain hidden until deletion works.

## Test Checklist

Run these in a disposable Supabase dev project before enabling accounts:

- Create a user, profile, follow rows, public links, likes, reports, and blocks.
- Call `DELETE /me/account` as that user.
- Confirm the auth user is removed or disabled according to the chosen backend
  implementation.
- Confirm profile, follows, public links, likes, reports, and blocks cascade.
- Confirm other users cannot delete the account.
- Confirm private/local library items are not uploaded or touched.
- Confirm public feed no longer shows deleted user's links.
- Confirm Apple token revocation behavior with Sign in with Apple.
- Confirm support/data-deletion page copy matches the product behavior.

## Prohibited

- Do not delete accounts directly from the consumer app with service-role keys.
- Do not log private notes, file names, screenshots, PDFs, Private Vault data,
  or raw clipboard contents during deletion.
- Do not expose raw SQL/RLS/service errors to users.
- Do not enable accounts/social externally until this runbook, OpenAPI,
  Supabase cascade behavior, privacy copy, and App Review notes are aligned.
