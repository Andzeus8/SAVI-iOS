# SAVI Security And Privacy

## Golden Rules

- Private Vault content never leaves the device unless a separate encrypted
  private backup plan is approved.
- Consumer apps never contain Supabase service-role keys, PostHog query keys,
  admin API keys, passwords, or moderation secrets.
- Public social publishing is explicit opt-in per item.
- Analytics use typed allowlisted events only.
- Admin dashboards are separate from the user app.

## App Store / Social Safety

Social must remain hidden in Release/TestFlight until SAVI has:

- report and block flows,
- feed exclusion for blocked users,
- delete/unpublish own public links,
- account deletion path,
- Sign in with Apple revocation when accounts are enabled,
- moderation workflow,
- updated privacy policy,
- updated App Store privacy labels,
- Apple review test account and notes.

## Secrets

Allowed in client apps:

- Supabase public anon key,
- PostHog project token if analytics is enabled,
- public API base URLs.

Never allowed in client apps:

- Supabase service-role key,
- PostHog personal/query API key,
- database password,
- admin backend key,
- private signing key,
- production `.env` file.

## Data Minimization

Do not collect:

- private note bodies,
- PDF/file contents,
- screenshots or OCR text,
- Private Vault data,
- raw clipboard content,
- keystrokes,
- contacts,
- private file names.

## Founder Hub Separation

The Mac Founder Hub is internal only. Live data must come from a protected admin
backend or PostHog dashboard path. It must not be compiled into the iPhone app
or share extension target.
