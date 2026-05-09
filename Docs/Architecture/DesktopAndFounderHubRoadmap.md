# SAVI Desktop And Founder Hub Roadmap

SAVI has two different desktop ideas. They must stay separate.

## Internal Mac Founder Hub

Purpose:

- founder dashboard,
- TestFlight/build room,
- product analytics view,
- moderation queue later,
- reliability and crash triage,
- Codex/work-log visibility.

Rules:

- Internal only.
- Can use mock data now.
- Live data must come from protected admin backend or PostHog Query path.
- Service-role keys and PostHog query keys must never be in source or iPhone
  bundles.
- Founder Hub code must not compile into the consumer iPhone app or share
  extension.
- Future moderation views must follow
  `Docs/Backend/AdminModerationWorkflow.md` and
  `Docs/Backend/OpenAPI/savi-admin-v1.openapi.yaml`.
- Founder Hub moderation should support public-link hide/unhide actions and the
  moderation audit log through a protected admin backend only.

## Future User-Facing Mac Companion

Purpose:

- view personal library,
- search saved links,
- browse folders,
- open web links,
- sync eligible account data,
- possibly save links from Mac later.

Rules:

- No founder dashboards.
- No admin credentials.
- No moderation tools unless user is an authenticated staff/admin in a separate
  admin surface.
- Private files and Private Vault stay local/iPhone-private until encrypted
  sync is designed.

## Suggested Phases

1. Keep current Mac Founder Hub internal/mock.
2. Add protected admin backend for live founder metrics and moderation.
3. Add user account/sync contract on iOS.
4. Build user-facing Mac companion against the same contract.
5. Add Android after API/schema/event contracts are stable.
