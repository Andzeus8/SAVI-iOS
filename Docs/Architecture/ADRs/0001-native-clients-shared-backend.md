# ADR 0001: Native Clients With Shared Backend Contract

## Status

Accepted.

## Decision

SAVI will stay native SwiftUI on iOS. Future Android should be native Kotlin /
Compose and reuse the same backend contract, schemas, event names, and product
rules. SAVI should not move to React Native as the default path.

## Rationale

- The current app is already native SwiftUI with a share extension, biometrics,
  App Group behavior, and iOS-specific UX.
- Native iOS gives better control over Share Sheet, Photos, Files, biometrics,
  widgets/intents later, and performance tuning.
- Android portability is best achieved through stable backend contracts and
  documented rules, not by forcing shared UI code too early.

## Consequences

- Client architecture must avoid burying business rules inside SwiftUI views.
- Backend field names, item types, folder IDs, and analytics events must remain
  platform-neutral.
- Android can start later without rewriting the backend.
