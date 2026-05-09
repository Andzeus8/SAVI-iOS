# SAVI Setup Checklist

Start with:

- `Docs/Architecture/CTOHandoffIndex.md`
- `Docs/Architecture/MasterRoadmap.md`
- `Docs/Architecture/AppStoreComplianceMatrix.md`
- `Docs/PublicSite/README.md`

## Apple

- Confirm App ID: `com.altatecrd.savi`.
- Confirm Share Extension ID: `com.altatecrd.savi.ShareExtension`.
- Confirm App Group is enabled for app and share extension.
- Confirm Sign in with Apple when accounts are ready.
- Confirm account deletion and Sign in with Apple revocation before accounts
  are exposed externally.
- Maintain privacy policy URL, support URL/email, beta notes, screenshots, and
  App Store privacy labels.
- Keep social hidden in Release until the social safety checklist is complete.

## Supabase

- Create `savi-dev`.
- Create `savi-prod`.
- Enable Auth providers.
- Run schema migrations from repo.
- Enable and test RLS on every exposed table.
- Store only URL and anon public key in client config.
- Keep service-role key server-side only.
- Configure backups and project access permissions.

## PostHog

- Create `SAVI Dev`.
- Create `SAVI Prod`.
- Disable autocapture and session replay for now.
- Add project token/host only after privacy copy and opt-in are ready.
- Build dashboards from allowlisted events.
- Keep personal/query API keys only in admin backend or Mac Keychain for internal
  founder use.

## Admin / Founder Hub

- Decide `admin.savi.app` or equivalent internal host.
- Require admin authentication.
- Keep service-role/PostHog query keys server-side.
- Add moderation queue before public social.
- Add audit log for admin actions.

## Notifications / APNs

- Do not enable push for the current private-save TestFlight.
- Design APNs through a protected backend only.
- Add device-token storage only after account auth exists.
- Keep APNs signing keys out of apps, Git, and client config.
- Use `Docs/Backend/NotificationRunbook.md` before implementing push.

## Public Site

- Buy/configure domain.
- Publish `/privacy`, `/terms`, `/support`, `/data-deletion`, and
  `/community-guidelines`.
- Build the static public site with `scripts/savi-public-site-build.py`.
- Verify the public-site packet with `scripts/savi-public-site-check.py`.
- Keep `Docs/PublicSite/` free of TODO placeholders before App Store submission.
- Replace `1080solutionsA@gmail.com` with a company support/privacy alias later
  if the domain setup creates one.

## Repo Governance

- Keep docs updated with each architecture-changing PR/chat pass.
- Read and update `Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md` when multiple chats
  are active.
- Add ADRs for decisions that change stack, privacy, sync, or release behavior.
- Update `Docs/Architecture/MasterRoadmap.md` when roadmap status changes.
- Update `Docs/Architecture/AppStoreComplianceMatrix.md` before App Store or
  social/account/analytics changes.
- Run `scripts/savi-safety-scan.sh` before backend/social/admin-sensitive
  changes.
