# SAVI Analytics Event Catalog

SAVI uses a typed, privacy-aware event allowlist. Do not add ad-hoc tracking calls.

## Product Events

| Event | Purpose | Safe Properties |
|---|---|---|
| `app_opened` | App usage and DAU/WAU/MAU | app version, build, OS, device tier, channel |
| `session_duration` | Time in app | duration seconds, app/device metadata |
| `onboarding_started` | Funnel start | source surface |
| `onboarding_completed` | Activation funnel | source surface |
| `share_extension_opened` | Share Sheet usage | source surface, count |
| `save_completed` | Core value metric | item type, source group, folder id/category, domain, public/private |
| `save_failed` | Reliability | source surface, item type, reason |
| `metadata_success` | Metadata pipeline health | item type, source group, folder id/category, domain, provider/reason |
| `metadata_failure` | Metadata failure rate | domain, reason |
| `folder_created` | Organization behavior | folder id/category, public/private |
| `folder_selected` | Folder/filter usage | folder id/category, source surface |
| `search_performed` | Search engagement | query-vs-filter result type, result count |
| `public_link_published` | Social publishing | count, social provider |
| `feed_viewed` | Social feed usage | source surface, count |
| `friend_added` | Social graph growth | social provider |
| `like_added` | Reaction usage | domain, social provider, liked/unliked |
| `friend_link_saved` | Social-to-personal value | item type, source group, folder id/category, domain |
| `report_submitted` | Safety/moderation | target kind, social provider |
| `block_action` | Safety/moderation | blocked/unblocked, social provider |

## Forbidden Data

Never send:

- private note text,
- private document contents,
- private PDF contents,
- screenshots or OCR text,
- Private Vault/private vault contents,
- raw clipboard contents,
- keystrokes,
- contacts,
- private file names,
- Supabase service-role keys or other secrets.

## Current Implementation

- `SaviAnalyticsEventName` and `SaviAnalyticsPropertyKey` are the app-side allowlist.
- Release/TestFlight uses a no-op analytics service unless a later PostHog integration is explicitly configured and the user opts in.
- Debug logs analytics events locally so payloads can be audited before PostHog exists.
- No PostHog SDK, autocapture, or session replay is active in this pass.
