# SAVI Domain And DNS Plan

## Recommended Setup

Buy one domain and manage DNS in Cloudflare or an equivalent registrar/DNS host.

Recommended DNS names:

- root domain for marketing and product pages,
- `www` for the same site,
- `admin` for internal Founder Hub/admin later,
- `api` for protected backend/admin API later,
- `links` for public profiles/links later,
- `support` optional support redirect,
- `privacy` optional privacy redirect.

## Email

Create or forward:

- `support@<domain>`
- `privacy@<domain>`
- `admin@<domain>`
- `founder@<domain>` optional

## Do Not Publish Yet

- Admin endpoints without authentication.
- Supabase service-role keys.
- PostHog query/personal keys.
- Production environment files.
