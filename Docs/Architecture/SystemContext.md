# SAVI System Context

## Product Surfaces

- **SAVI iOS app**: personal library, Home, Search, Explore, Folders/Keepers,
  Profile, Private Vault, archive export/import, onboarding, and sample library.
- **Share extension**: fast save surface from Safari, YouTube, Photos, Files,
  social apps, text, PDFs, and generic files.
- **SAVI Mac**: internal/development companion and Founder Hub. This is not the
  consumer app and must not ship admin secrets.
- **Future Android app**: native Android client using the same backend contract.
- **Future admin surface**: protected `admin.savi.app` or equivalent backend
  dashboard for founder/team analytics and moderation.

## Data Classes

| Class | Examples | Default Storage | Can Be Public? |
|---|---|---|---|
| Personal saves | notes, links, screenshots, files | local app storage/archive | no |
| Private Vault | IDs, insurance, codes, sensitive notes | local/private only | never |
| Public web links | user-explicitly published URLs | Supabase social tables | yes |
| Analytics events | save completed, metadata failure | PostHog manual events | n/a |
| Admin metrics | dashboards, moderation queues | admin backend/PostHog | n/a |

## Trust Boundaries

- Consumer app code is untrusted for admin operations.
- Supabase anon keys are public client keys; security comes from RLS.
- Service-role keys, PostHog query keys, and moderation tools belong only on
  a protected server or internal admin tool.
- Share extension input is untrusted and must be normalized before saving.
- Public social content must be user-approved, reportable, blockable, and
  removable.

## Local-First Rule

SAVI must remain useful before login. Accounts should unlock sync/social, not
block saving. The app should save locally first, then sync eligible records when
the user opts into an account.
