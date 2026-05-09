# ADR 0003: Founder Hub And Admin Separation

## Status

Accepted.

## Decision

Founder Hub dashboards and admin capabilities must remain outside the consumer
iPhone app and share extension. The current Mac Founder Hub is internal-only.
Live admin data should eventually come through a protected admin backend or a
server-side PostHog Query API path.

## Rationale

Regular users should never receive dashboard logic, mock business metrics,
moderation tools, service-role keys, PostHog query keys, or admin-only strings
inside the production app bundle.

## Consequences

- Mac Founder Hub source must be target-scoped to `SAVI Mac`.
- iOS Release/TestFlight can contain privacy-safe analytics event plumbing, but
  not founder dashboards.
- Admin keys and query credentials belong server-side or in an internal tool's
  secure storage, never in source.
