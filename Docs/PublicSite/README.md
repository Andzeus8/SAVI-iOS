# SAVI Public Site Templates

These are publication-ready draft pages for the future SAVI domain. They are not
legal advice. Before App Store submission, review them against the exact build,
privacy labels, backend configuration, public domain, and company/legal
requirements.

## Recommended URLs

Use one domain and these paths:

- `/privacy`
- `/terms`
- `/support`
- `/data-deletion`
- `/community-guidelines`

Optional subdomains later:

- `admin.<domain>` for protected founder/admin tools,
- `api.<domain>` for protected backend/admin APIs,
- `links.<domain>` for public link/profile pages if social launches.

## Files

- `privacy.md` - privacy policy draft.
- `terms.md` - terms draft.
- `support.md` - support and feedback page.
- `data-deletion.md` - account/data deletion instructions.
- `community-guidelines.md` - social/public-link rules for future launch.
- `domain-dns-plan.md` - domain and DNS setup plan.
- `StaticSitePublishing.md` - static HTML export/deployment instructions.

## Current Draft Contact

The current beta support/privacy/deletion contact in these drafts is:

- `1080solutionsA@gmail.com`

Replace it with a company support alias later if the public domain setup creates
one.

## Static HTML Export

Build a deployable static site into `build/public-site/`:

```bash
scripts/savi-public-site-build.py
```

Check the public-site packet:

```bash
scripts/savi-public-site-check.py
```
