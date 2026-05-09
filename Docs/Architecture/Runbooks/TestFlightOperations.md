# SAVI TestFlight Operations

Use this runbook whenever a tester says they did not receive an invite, still
see an old build, or are not sure how to install the latest SAVI beta.

Run this checker before TestFlight-sensitive handoffs:

```bash
scripts/savi-testflight-ops-check.py
```

## Current TestFlight Truth

- App: `SAVI`
- Release bundle ID: `com.altatecrd.savi`
- Share extension bundle ID: `com.altatecrd.savi.ShareExtension`
- Latest local project build: `34`
- Latest uploaded TestFlight build: `1.0 (34)`
- Internal group: `SAVI Internal`
- First beta posture: iPhone-only, private-save-first, social hidden

## Internal Testers To Verify

Verify these emails in App Store Connect before assuming everyone has the latest
build:

- `altatecrd@gmail.com`
- `matti.lamminsalo@gmail.com`
- `andreusbl@icloud.com`
- `andreusbl@mac.com`
- `luimi2k1@gmail.com`
- `j.rodriguez28@icloud.com`

Internal testers must be App Store Connect users with access to SAVI. If an
email is not listed in the internal tester picker, invite that person under
Users and Access first, wait for acceptance, then add them to the internal
group.

## Assign Latest Build To Internal Group

After uploading a new build:

1. Open App Store Connect.
2. Go to Apps.
3. Select `SAVI: Save Now, Find Later.`.
4. Open the TestFlight tab.
5. Confirm build `1.0 (34)` has finished processing.
6. Open Internal Testing.
7. Select `SAVI Internal`.
8. If the build is not listed under Builds, click Add Builds.
9. Select `1.0 (34)`.
10. Paste the current What to Test notes from
    `Docs/Architecture/Runbooks/AppStoreConnectMetadata.md`.
11. Click Add.

If automatic distribution is enabled for `SAVI Internal`, new builds may be
sent to the group automatically. Still verify the newest build appears in the
group after processing.

## Invite Or Reinvite Internal Testers

1. In App Store Connect, open Apps > SAVI > TestFlight.
2. Under Internal Testing, select `SAVI Internal`.
3. Click Invite Testers.
4. Select the accepted App Store Connect users.
5. Click Add.

If a tester cannot be selected:

- confirm they accepted the App Store Connect user invite,
- confirm their role has access to the SAVI app,
- confirm they are not only an external tester record,
- confirm the email is the Apple ID they use for TestFlight.

## Tester Install Instructions

Send this to testers:

```text
1. Install Apple's TestFlight app from the App Store.
2. Accept the SAVI TestFlight invite email.
3. Open TestFlight.
4. Tap SAVI.
5. Confirm the build says 1.0 (34).
6. Tap Install or Update.
7. If it still shows an old build, pull down to refresh TestFlight, quit and
   reopen TestFlight, or delete/reinstall SAVI from TestFlight.
```

TestFlight updates are over-the-air, but they are not a magic silent update.
The tester may need to open TestFlight and tap Update, especially if the app was
already installed.

## Old Build Troubleshooting

If a tester still sees an old version:

- Confirm build `1.0 (34)` is processed.
- Confirm build `1.0 (34)` is assigned to `SAVI Internal`.
- Confirm the tester is in `SAVI Internal`, not only invited to App Store
  Connect.
- Confirm the tester accepted the invite with the same Apple ID used in
  TestFlight.
- Ask the tester to open TestFlight, pull to refresh, and tap Update.
- If TestFlight still shows the old build, ask the tester to delete SAVI from
  TestFlight and reinstall from the invite.
- If the tester reports a crash or freeze, ask them to submit TestFlight feedback
  feedback immediately after reproducing so the crash/log attaches to the
  correct build.
- Use `Docs/Architecture/Runbooks/CrashAndPerformanceTriage.md` for launch
  crashes, freezes, slow scrolling, thumbnail jank, or iPhone 11/iOS 17-style
  reports.

## Build Expiry And Access Notes

- Internal testers can test builds for 90 days.
- Internal testing is limited to App Store Connect users with app access.
- External testers use a separate TestFlight Beta App Review path.
- Builds marked internal-only can only be added to internal groups.

## Release Discipline

- Upload only the `SAVI` Release app for TestFlight, not `SAVI Test`.
- Verify bundle ID `com.altatecrd.savi`.
- Verify embedded extension bundle ID `com.altatecrd.savi.ShareExtension`.
- Keep social hidden in Release/TestFlight.
- Do not enable Supabase/PostHog/CloudKit/social as live features unless the
  compliance docs and App Store metadata are updated first.

## Source Anchors

- [Apple: Add internal testers](https://developer.apple.com/help/app-store-connect/test-a-beta-version/add-internal-testers)
- [Apple: Add testers to builds](https://developer.apple.com/help/app-store-connect/test-a-beta-version/add-testers-to-builds)
- [Apple: TestFlight overview](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/)
