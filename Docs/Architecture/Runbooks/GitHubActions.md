# SAVI GitHub Actions

SAVI has a credential-free preflight workflow:

`/.github/workflows/savi-preflight.yml`

## Automatic Checks

On pull requests and pushes to `main` or `develop`, GitHub Actions runs:

```bash
scripts/savi-preflight.sh
```

This checks:

- whitespace/diff errors,
- founder/admin dashboard separation,
- likely committed secrets,
- documentation front doors,
- backend/social contract readiness,
- App Store readiness,
- public-site TODO reminders.

## Manual Build Gate

From the GitHub Actions UI, run `SAVI Preflight` manually and set
`run_builds = true`.

That runs:

```bash
scripts/savi-preflight.sh --all-builds
```

This adds:

- iOS Release generic iPhoneOS no-sign build,
- `SAVI Mac` Debug build,
- `SAVI Mac` Release build.

## What This Workflow Does Not Do

- No TestFlight upload.
- No signing credentials.
- No App Store Connect API keys.
- No Supabase or PostHog secrets.
- No production deployment.

Those should be added only after the team intentionally designs secure CI
secrets, branch permissions, and release approvals.
