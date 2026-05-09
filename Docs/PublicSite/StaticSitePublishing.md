# SAVI Public Site Static Publishing

The public-site Markdown pages in this folder can be exported into a small
static HTML site. This gives SAVI a deployable privacy/support/terms packet for
App Store Connect once the public domain is ready.

Build the site:

```bash
scripts/savi-public-site-build.py
```

Output:

```text
build/public-site/
```

Generated pages:

- `index.html`
- `privacy.html`
- `terms.html`
- `support.html`
- `data-deletion.html`
- `community-guidelines.html`

Run the checker:

```bash
scripts/savi-public-site-check.py
```

The checker verifies that:

- required public-site source files exist,
- source pages have no unfinished placeholders,
- the current beta support email is present,
- the domain/DNS plan still warns against publishing service-role keys,
- generated HTML exists,
- generated HTML has SAVI branding,
- generated HTML has no unfinished placeholders.

## Deployment Shape

When the domain is ready, upload the contents of `build/public-site/` to any
static host that can serve HTTPS pages. Good low-maintenance options:

- Cloudflare Pages,
- Netlify,
- Vercel static output,
- GitHub Pages from a separate public site repo.

Recommended public URLs:

- `/privacy` or `/privacy.html`
- `/terms` or `/terms.html`
- `/support` or `/support.html`
- `/data-deletion` or `/data-deletion.html`
- `/community-guidelines` or `/community-guidelines.html`

Use whichever URL style the chosen host supports cleanly, then enter the final
Privacy Policy URL and Support URL in App Store Connect.

## Do Not Publish

Do not publish or commit:

- Supabase service-role keys,
- PostHog personal/query API keys,
- App Store Connect API keys,
- APNs signing keys,
- production `.env` files,
- private tester data,
- exported user archives,
- Founder Hub admin pages.
