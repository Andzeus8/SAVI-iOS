# SAVI Backend Architecture

## Recommended Stack

- **Supabase**: accounts, profiles, follows, public web links, likes, reports,
  blocks, and future sync tables.
- **PostHog**: privacy-safe product analytics, activation funnels, retention,
  reliability, and founder dashboards.
- **Admin backend**: later protected server/API for moderation, PostHog Query
  API, service-role actions, and team-only dashboards.
- **CloudKit**: optional Apple-private backup/sync later, not social or
  analytics.

## Supabase Setup

Create separate projects:

- `savi-dev`
- `savi-prod`

Required rules:

- All exposed tables have RLS enabled.
- iOS/Android/Mac clients only receive Supabase URL and anon key.
- Service-role keys stay server-side only.
- Migrations are checked into the repo and reviewed before production.
- Staging data can be fake; production data cannot be copied into local/dev
  machines without an explicit privacy process.

Social V1 tables already have a draft in:

`/Users/guest1/Documents/SAVI-iOS/Docs/Backend/Supabase/social_v1_schema.sql`

## PostHog Setup

Create separate projects:

- `SAVI Dev`
- `SAVI Prod`

Rules:

- Manual event capture only.
- Autocapture and session replay off for now.
- No private note text, screenshots, PDF contents, file names, clipboard text,
  Private Vault content, keystrokes, or contacts.
- Public/trending dashboards may use domains and explicit public URLs only.

## Admin Backend

The admin backend is optional for the first TestFlight, but required before
real social moderation and live Founder Hub dashboards.

Responsibilities:

- moderation queues,
- report/block review,
- public-link hide/unhide actions,
- account deletion support,
- PostHog Query API calls,
- Supabase service-role actions,
- internal dashboard auth,
- audit logging for admin actions,
- moderation audit log.

Do not put these responsibilities into the iPhone app.

## Draft Contracts

- `Docs/Backend/OpenAPI/savi-social-v1.openapi.yaml` - consumer social/public-link contract.
- `Docs/Backend/OpenAPI/savi-admin-v1.openapi.yaml` - protected admin moderation API draft.
- `Docs/Backend/AdminModerationWorkflow.md` - protected moderation queue and audit workflow.
