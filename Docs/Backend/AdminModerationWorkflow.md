# SAVI Admin Moderation Workflow

This workflow is for the protected admin surface only. It must never run from
the consumer iPhone app, the share extension, or the user-facing Mac companion.

The purpose is to make SAVI's future social layer reviewable, supportable, and
App-Store-safe before any external social launch.

## Scope

Moderation V1 covers:

- reported public web links,
- reported profiles,
- user blocks,
- public-link hide and unhide actions,
- public-link eligibility review,
- account deletion/support follow-up,
- moderation audit logging.

Moderation V1 explicitly excludes:

- DMs,
- comments,
- contacts upload,
- public PDFs,
- public screenshots,
- private files,
- Private Vault content,
- private note text,
- raw personal library contents,
- raw clipboard data.

## Roles

- **Reporter**: a signed-in user who reports a public link or profile.
- **Reported user**: the account whose public content or profile is reported.
- **Moderator**: an internal staff user allowed to review reports.
- **Admin backend**: protected server path that can use service-role keys and
  PostHog Query credentials server-side only.

Service-role keys, PostHog Query keys, passwords, and admin session material
must never be stored in source control or shipped in iOS, share extension, or
consumer Mac app bundles.

## Report States

Reports use exactly these states:

- `open`
- `reviewing`
- `actioned`
- `dismissed`

The same state set must stay aligned across:

- `Docs/Backend/Supabase/social_v1_schema.sql`
- `Docs/Backend/OpenAPI/savi-admin-v1.openapi.yaml`
- `Docs/Backend/Supabase/rls_test_plan.sql`

## Queue Requirements

The protected moderation queue should support:

- newest open reports first,
- status filtering,
- target type filtering for profile versus public link,
- linked public URL and domain only,
- reporter count,
- block count,
- target public-link visibility state,
- block relationship context,
- redacted profile/public-link details,
- direct action recording.

The queue must not display private notes, screenshots, PDFs, vault items, private
file names, or personal library contents.

## Moderator Actions

Moderators can:

- mark a report as `reviewing`,
- dismiss a report,
- mark a report as `actioned`,
- hide a public link,
- unhide a public link,
- add a reason category,
- add a private staff note,
- escalate to account deletion/support follow-up.

Staff notes must be treated as internal support data. They should not be sent to
analytics, public feeds, or user clients.

## Audit Log

Every admin action must create a moderation audit log row with:

- `action_id`,
- `moderator_id`,
- `action_type`,
- `target_user_id`,
- `target_link_id`,
- `report_id`,
- `previous_status`,
- `new_status`,
- `reason_category`,
- `note_present`,
- `created_at`.

The audit log can record that a note exists with `note_present`, but should not
copy private content into analytics or public-facing payloads.

## App Store Readiness Gate

External social stays hidden until all of this is true:

- in-app report flow exists,
- in-app block flow exists,
- user can delete or unpublish their own public links,
- user can delete their account,
- protected admin moderation queue exists,
- moderation audit log exists,
- support contact is public,
- privacy policy covers accounts/social/analytics,
- App Review notes explain UGC controls,
- Apple has a test account and clear review instructions,
- Release/TestFlight social gates have been intentionally opened.

Until then, Release/TestFlight should keep only the small "Friends are coming"
teaser and no public publishing controls.
