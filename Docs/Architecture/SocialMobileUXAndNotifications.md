# SAVI Social Mobile UX And Notifications

This document lays out the social and notification basics. It is a design and
product contract, not an instruction to enable social in Release.

## Release Gate

Release/TestFlight must keep social hidden except for a small "Friends are
coming" teaser until Social V1 safety is complete.

## Mobile Social Surfaces

### Profile / Account

- Sign in with Apple.
- Username claim/edit.
- Display name and avatar/color.
- Public sharing toggle.
- Account deletion entry.
- Privacy/social status copy.

### Explore / Friends

- Release: personal Explore only plus subtle teaser.
- Debug/Social Lab: Friends feed tab, public link cards, follow state.
- Public feed cards show only explicit public web links.
- Cards expose heart, save to my library, report, and block entry points.

### Public Link Publish Sheet

- Only appears on eligible web-link saves.
- Shows public preview before publishing.
- Explains that PDFs, files, screenshots, Private Vault, and private notes cannot
  be published.
- Requires explicit publish action.
- Allows unpublish/delete later.

### Friend / User Profile

- Username, display name, public link count, follow button.
- Report user.
- Block user.
- List of visible public links.
- Empty state if blocked, hidden, or no public links.

### Safety Flows

- Report profile/link with reason.
- Block/unblock user.
- Hidden content message.
- Delete/unpublish own public link.
- Account deletion entry.

## Notifications

Notifications are optional and should come after accounts/social are stable.
The detailed APNs/device-token/settings contract lives at
`Docs/Backend/NotificationRunbook.md`.

### Allowed Notification Types

- New follower/friend.
- Someone liked your public link.
- A friend saved a public link you shared.
- Moderation status update.
- Product/account/security notices.

### Not Allowed

- Private Vault content.
- Private note text.
- Private file names.
- Screenshot contents.
- Recovery codes, door codes, IDs, insurance, or other sensitive samples.
- Spammy engagement nags.

### Notification Rules

- Ask permission only after the user understands the value.
- Provide in-app notification settings.
- Keep notification text generic and privacy-safe.
- Do not enable push notifications before backend auth and device-token storage
  are designed.
- Use APNs through a protected backend; do not send push directly from clients.
- Delete or disable device-token records on logout and account deletion.

## Debug Mock First

Before live accounts:

- use mock profiles,
- use mock follows,
- use mock public links,
- use mock notifications inside Debug/SAVI Test only,
- keep Release/TestFlight social disabled.
