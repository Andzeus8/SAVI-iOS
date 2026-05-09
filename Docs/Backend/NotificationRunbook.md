# SAVI Notification And APNs Runbook

Notifications are a later phase. They must not be enabled in Release/TestFlight
until accounts, backend auth, privacy copy, and device-token handling are ready.

This runbook defines the safe future contract for APNs, social/account
notifications, and user settings. It does not add APNs entitlements, register
devices, or collect tokens in the current private-save release.

## Current Release

The current TestFlight app should not request push notification permission.
There is no live APNs backend, no device-token storage, and no notification
delivery path in Release.

## Allowed Notification Types

Future notifications may include:

- new follower,
- public-link like,
- friend saved your public link,
- moderation status update,
- account/security notice,
- backup/sync status notice if private backup is later enabled.

## Forbidden Notification Content

Notification payloads and analytics must never include:

- Private Vault content,
- private note text,
- private file names,
- screenshot contents,
- OCR text,
- PDFs or file contents,
- recovery codes,
- door codes,
- IDs, insurance, passports, or other sensitive samples,
- raw search queries,
- raw clipboard contents.

Notification text should stay generic, for example:

- `Someone liked your public link.`
- `You have a new follower.`
- `A report was reviewed.`

## Permission Timing

Ask for notification permission only after a user understands the value. Good
moments:

- after they follow someone,
- after they publish a public web link,
- after they enable account/security notices.

Do not ask on first launch.

## Backend Contract

The future backend should expose:

- `POST /me/device-tokens`
- `DELETE /me/device-tokens/{id}`
- `GET /me/notification-settings`
- `PUT /me/notification-settings`

Only the protected backend sends APNs pushes. Consumer clients register and
delete their own device token records with normal user auth; they never send
pushes directly and never receive APNs signing keys.

## Device Token Storage

Device-token records may contain:

- `id`,
- `user_id`,
- APNs token,
- platform (`ios` or `macos`),
- app version/build,
- environment (`sandbox` or `production`),
- created/last-seen timestamps,
- disabled timestamp.

Device-token records must not contain private item titles, screenshots, notes,
files, vault content, raw clipboard data, or raw search queries.

Account deletion and logout must delete or disable device-token records.

## User Settings

Users need in-app settings for:

- master notifications on/off,
- social notifications,
- moderation/status notifications,
- account/security notifications,
- backup/sync notifications if that feature launches.

Settings must be respected server-side before sending APNs pushes.

## Delivery Rules

- Use APNs through a protected backend.
- Use collapse/thread identifiers only for generic categories.
- Do not put private content in title, body, subtitle, sound name, category,
  thread id, analytics labels, or deep-link parameters.
- Deep links should open a safe in-app destination and re-check auth/state.
- Blocked users must not trigger social notifications to each other.
- Hidden/deleted public links must not generate new engagement notifications.

## Analytics Rules

Allowed notification analytics properties:

- notification type,
- delivery surface,
- app build,
- OS version,
- permission status,
- sent/opened/failed status,
- failure bucket.

Forbidden properties:

- message body,
- private title text,
- URL for private saves,
- screenshot/OCR/file/vault content,
- raw search query,
- APNs token.

## Test Checklist

Before enabling push externally:

- Confirm Release currently does not request permission unexpectedly.
- Confirm user can turn notification categories off.
- Confirm logout/account deletion disables device tokens.
- Confirm blocked users cannot trigger social notifications.
- Confirm hidden/deleted public links do not send new engagement notifications.
- Confirm APNs keys live only in protected backend infrastructure.
- Confirm App Store privacy labels and privacy policy mention notifications and
  device tokens if used.
- Confirm notification copy is privacy-safe on the lock screen.
- Confirm Apple App Review notes explain notification behavior if social is
  enabled.
