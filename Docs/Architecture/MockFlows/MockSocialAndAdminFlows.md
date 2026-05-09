# SAVI Mock Social And Admin Flows

These flows can be built before Supabase/PostHog accounts exist. They should be
Debug/SAVI Test or Mac Founder Hub only.

## Mock Mobile Social

- Mock current user profile.
- Mock username claim success/failure.
- Mock friend search by username.
- Mock follow/unfollow.
- Mock friends feed with public web links only.
- Mock heart/unheart.
- Mock save friend link into personal library.
- Mock report and block actions.
- Mock publish eligibility rejection for files, PDFs, screenshots, Private Vault,
  and private notes.

## Mock Mac Founder Hub Admin

- Moderation queue with reported links/users.
- Report detail view.
- Hide link action.
- Dismiss report action.
- Blocked user overview.
- Reliability room fed by mock save/metadata failures.
- TestFlight room fed by manual build/tester status.

## Safety Requirements

- Mock flows must never be visible in Release/TestFlight unless explicitly gated
  as non-functional teaser copy.
- Mock admin strings and metrics must not compile into the iPhone app target.
- No real service keys or private user data in mock fixtures.
