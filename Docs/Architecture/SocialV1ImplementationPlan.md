# SAVI Social V1 Implementation Plan

Social V1 turns SAVI from a private library into a safe public-link discovery
network. Release/TestFlight must keep social hidden until report/block,
moderation, delete/unpublish, privacy labels, and App Review notes are complete.

## Allowed Social V1 Scope

- profiles,
- username,
- follow/friend by username,
- friends feed,
- explicit public web-link cards only,
- one heart reaction,
- save a friend's public link,
- report,
- block.

Excluded from V1:

- DMs,
- comments,
- contacts upload,
- public PDFs,
- public screenshots,
- private files,
- Private Vault,
- local private notes/documents.

## Phase 1: Account, Profile, Username

- Enable Supabase Auth in dev.
- Add Sign in with Apple for account creation.
- Create profile from authenticated user.
- Claim/update username with server/RLS validation.
- Add account deletion design before any external account launch using
  `Docs/Backend/AccountDeletionRunbook.md`.
- Keep Release social gate off.

## Phase 2: Follow Graph

- Follow/unfollow by username.
- Show basic following/follower state.
- Block self-follow and duplicate follow.
- Keep block table ready before public feed is exposed.

## Phase 3: Explicit Public Web-Link Publishing

- Add app-side eligibility check: only normal web links, articles, videos, and
  places.
- Exclude files, PDFs, screenshots, images, Private Vault, and private notes.
- Require explicit publish action and public preview.
- Add unpublish/delete before external launch.

## Phase 4: Friends Feed, Hearts, Save Friend Link

- Fetch feed of visible non-hidden public links.
- Exclude blocked users in both directions.
- Add heart/unheart.
- Save friend's public link into personal library as a private copy.
- Track only safe analytics properties.

## Phase 5: Safety, Moderation, And Deletion

- Add report profile/link flow.
- Add block user flow.
- Add moderation queue in protected admin backend or Founder Hub path.
- Add content hide/remove behavior.
- Add account deletion and public-content deletion behavior.
- Verify `DELETE /me/account`, Sign in with Apple revocation, and Supabase
  cascade behavior.
- Add public support/contact route.

## Phase 6: External Social Readiness

- Test RLS policies.
- Update privacy policy.
- Update App Store privacy labels.
- Prepare App Review notes and test account.
- Run abuse-path QA: report, block, delete, unpublish, hidden content, blocked
  feed, private item publish rejection.
- Only then consider enabling social in Release.

## Notifications Later

Notifications should be a separate phase after social is stable. The allowed
notifications are new follower, public-link like, friend saved your public link,
moderation status, and account/security notices. Notification text must never
include Private Vault content, private note text, file names, recovery codes, or
screenshots.

## Implementation References

- Schema draft: `Docs/Backend/Supabase/social_v1_schema.sql`
- Safety checklist: `Docs/Backend/SocialSafetyChecklist.md`
- Analytics catalog: `Docs/Backend/AnalyticsEventCatalog.md`
- Security rules: `Docs/Architecture/SecurityAndPrivacy.md`
- Mobile UX/notifications: `Docs/Architecture/SocialMobileUXAndNotifications.md`
