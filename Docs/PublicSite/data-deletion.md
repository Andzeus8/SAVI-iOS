# SAVI Data Deletion

This page is required before account-based features launch.

## Current Private-Save Release

If SAVI is being used without an account, your saved library is local to your
device. You can delete saved items in the app or remove the app to delete local
app data from the device.

## Future Account Release

When accounts launch, SAVI must provide an in-app way to delete your account and
associated account data. The backend contract for this future feature is
`DELETE /me/account`, with Sign in with Apple revocation where applicable.

Planned deletion coverage:

- profile,
- username,
- follows,
- public links,
- likes,
- reports/blocks where legally appropriate,
- account-linked sync records.

Private device-local data may also need separate local deletion controls.

## Contact

Deletion requests: 1080solutionsA@gmail.com
