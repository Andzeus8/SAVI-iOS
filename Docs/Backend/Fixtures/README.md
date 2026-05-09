# SAVI Backend Contract Fixtures

These fixtures are safe, fake examples used to keep iOS, future Android,
Supabase, PostHog, and admin tooling aligned.

## Folders

- `valid/` contains payloads that should pass the contract validator.
- `invalid/` contains examples that must fail, usually because they represent
  unsafe or disallowed behavior.

## Validator

Run:

```bash
scripts/savi-contract-fixtures-check.py
```

The validator intentionally uses only Python standard library code so it can run
locally and in GitHub Actions without installing dependencies.
