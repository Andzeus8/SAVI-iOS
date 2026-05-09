# SAVI Supabase Prep

This folder contains credential-free Supabase prep. Do not add real project
URLs, service-role keys, JWTs, or passwords here.

## Files

- `social_v1_schema.sql` - current Social V1 schema/RLS draft.
- `rls_test_plan.sql` - manual RLS test plan to run in a disposable dev project.

## Setup Order Later

1. Create `savi-dev`.
2. Create `savi-prod`.
3. Enable Sign in with Apple.
4. Run schema in dev.
5. Run RLS tests in dev with multiple fake users.
6. Only then connect Debug/SAVI Test to dev using public URL + anon key.
