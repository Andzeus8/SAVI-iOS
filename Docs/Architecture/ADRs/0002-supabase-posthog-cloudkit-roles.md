# ADR 0002: Supabase, PostHog, And CloudKit Roles

## Status

Accepted.

## Decision

- Supabase is the future backend for accounts, social, and public web-link sync.
- PostHog is the product analytics and founder dashboard source.
- CloudKit is only optional Apple-private backup/sync later.
- CloudKit is not the social network and not the analytics system.

## Rationale

Supabase gives SAVI a cross-platform backend for iOS, Android, web/admin, and
Mac tooling. PostHog is designed for product analytics and dashboarding.
CloudKit is Apple-specific, making it a poor foundation for Android social or
company analytics, but still useful later for private Apple ecosystem backup.

## Consequences

- Social tables must have RLS and App Store safety flows.
- Analytics must use a privacy allowlist.
- iCloud features can be disabled without breaking SAVI's core local value.
- Android can use the same Supabase/PostHog contracts later.
