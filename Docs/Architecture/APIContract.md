# SAVI API Contract

The backend contract should be stable before Android begins. The first version
can be Supabase-direct for simple reads/writes, but the product should document
the same contract as if it were an API.

## Auth

V1 account auth:

- Sign in with Apple,
- optional email magic link later,
- no contacts upload.

Client receives:

- user ID,
- display name,
- username,
- avatar URL if set,
- account deletion/status flags.

Before accounts launch externally, the backend contract must include account
deletion. The current Social V1 OpenAPI draft includes `DELETE /me/account`;
the production implementation must revoke Sign in with Apple credentials where
applicable and delete/cascade profile, follows, public links, likes, reports, and blocks.
The detailed account deletion runbook lives at
`Docs/Backend/AccountDeletionRunbook.md`.

## Social V1

Required capabilities:

- create/update profile,
- claim username,
- follow/unfollow by username,
- list following/followers as allowed,
- publish eligible public web link,
- unpublish/delete own public link,
- fetch friends feed,
- like/unlike public link,
- save friend link to personal library,
- report profile/link,
- block/unblock user,
- delete account and social data.

Required exclusions:

- DMs,
- comments,
- contacts upload,
- public PDFs/files/screenshots,
- private vault publishing.

## Sync V1

Sync should start with low-risk records:

- public web links,
- folder definitions,
- tags,
- account profile.

Private file and Private Vault sync should wait for a separate encrypted sync
design.

## Error Shape

All backend errors should map to:

- user-safe message,
- machine-readable code,
- retryable boolean,
- correlation/request ID if available.

Do not surface raw SQL, RLS policy names, service errors, or secrets to users.
