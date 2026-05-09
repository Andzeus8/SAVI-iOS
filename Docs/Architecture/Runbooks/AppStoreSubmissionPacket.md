# SAVI App Store Submission Packet

Use this packet when preparing TestFlight, external beta review, or full App
Store review. It is written so the founder, another Codex chat, or a future CTO
can fill App Store Connect without hunting through the repo.

Run this before relying on the packet:

```bash
scripts/savi-appstore-readiness-check.py
scripts/savi-appstore-metadata-check.py
scripts/savi-appstore-age-rating-check.py
scripts/savi-appstore-export-compliance-check.py
```

## Source Of Truth

- Active repo: `/Users/guest1/Documents/SAVI-iOS`
- Release app target: `SAVI`
- Release bundle ID: `com.altatecrd.savi`
- Share extension bundle ID: `com.altatecrd.savi.ShareExtension`
- Debug/internal app: `SAVI Test`
- Debug/internal bundle ID: `com.altatecrd.savi.personaldebug`
- Current project/latest uploaded build: `1.0 (34)`; verify in
  `Docs/TestFlightReadiness.md` before submission
- First public posture: iPhone only, portrait only, private-save-first
- Social posture: hidden in Release/TestFlight until moderation, report/block,
  delete/unpublish, privacy labels, and App Review notes are complete
- iCloud/CloudKit posture: optional private backup later; do not present broken
  cloud backup in Release
- Analytics posture: no live PostHog external analytics unless configured,
  documented, privacy-labeled, and user-facing copy is updated

## App Store Connect Fields

| Field | Recommended Value |
|---|---|
| App name | `SAVI: Save Now, Find Later.` |
| Subtitle | `Save anything. Find it later.` |
| Primary category | Productivity |
| Secondary category | Utilities |
| Support URL | Founder-provided public support page |
| Privacy Policy URL | Founder-provided public privacy page |
| Beta feedback email | `1080solutionsA@gmail.com` unless replaced by support alias |
| Marketing URL | Optional for first TestFlight |
| Copyright | Founder/company legal name |
| SKU | `savi-ios` or another stable internal SKU |

For the more detailed copy-paste metadata packet, use
`Docs/Architecture/Runbooks/AppStoreConnectMetadata.md`.

Age Rating Packet:

- `Docs/Architecture/Runbooks/AppStoreAgeRating.md`
- `scripts/savi-appstore-age-rating-check.py`

Use that packet before answering the App Store Connect age-rating
questionnaire. It captures the current private-save-first posture: no gambling,
no contests, no unrestricted web browser, no live public social feed, no DMs or
comments, no public user-generated PDFs/screenshots/files/vault content,
neutral health research examples, and the future changes that trigger
re-rating.

Do not submit final legal/contact fields until the public site/domain is live
and the founder has approved the exact public pages.

Public-site drafts can be exported with:

```bash
scripts/savi-public-site-build.py
```

The generated files land in `build/public-site/` and can be uploaded to a
static host once the public domain is ready.

TestFlight operations:

- `Docs/Architecture/Runbooks/TestFlightOperations.md`
- `scripts/savi-testflight-ops-check.py`

Use that runbook when assigning the current build to `SAVI Internal`, adding
testers, or troubleshooting a tester who still sees an old build.

Share Extension real-device QA:

- `Docs/Architecture/Runbooks/ShareExtensionRealDeviceQA.md`
- `scripts/savi-share-extension-qa-check.py`

Use that runbook before relying on Share Sheet behavior in a submitted build.
It covers Safari/Photos/Files/YouTube, social/video links, plain text, PDFs,
generic files, metadata fallback, app-group import, and privacy-safe tester
notes.

Archive export/restore QA:

- `Docs/Architecture/Runbooks/ArchiveExportRestoreQA.md`
- `scripts/savi-archive-restore-check.py`

Use that runbook before relying on full archive export/import in a submitted
build. It covers Profile backup UI, preparing/loading state, iOS share/file
sheet, compact JSON backup, invalid file handling, private-content warnings,
fresh-install restore, and the guarantee that restore does not publish or
upload anything in Release.

Export Compliance Packet:

- `Docs/Architecture/Runbooks/AppStoreExportCompliance.md`
- `scripts/savi-appstore-export-compliance-check.py`

Use that packet before answering App Store Connect export compliance. The
current iOS app/share extension posture is `ITSAppUsesNonExemptEncryption = NO`
in both Info.plists and appears limited to Apple/system services plus normal
HTTPS/TLS transport. Founder/legal must still confirm the final App Store
Connect answer for the exact submitted build.

## TestFlight Beta Description

```text
SAVI is a pocket organizer for the useful things you find across your digital
life: links, screenshots, PDFs, videos, Wi-Fi codes, notes, files, and little
ideas you may want again later.

Add SAVI to the iOS Share Sheet once, then save from Safari, YouTube, Photos,
Files, Messages, and the apps you already use. SAVI helps name each save, add
smart tags, choose a folder, and make it easy to search by title, note, tag,
folder, source, file type, or the tiny clue you remember.

This beta is focused on the everyday basics: quick saving, search, folders,
Private Vault, archive backup, and feedback. Explore is a fun way to browse
your own saved favorites. Social sharing is still in progress and is not active
in this build.
```

## What To Test

```text
Try SAVI the way you would naturally use it:

1. Open the welcome flow and pin SAVI in your iOS Share Sheet.
2. Save a normal link, YouTube video, screenshot, image, PDF/file, and plain
   text from the Share Sheet.
3. Open SAVI and check that the save appears with a useful title, thumbnail,
   smart tags, and a sensible folder.
4. Try Home, Search, Explore, Folders, Private Vault, preview opening, archive
   export, and Help & Feedback.
5. Send feedback through TestFlight, directly to Andreus, or by email.

This build intentionally keeps public social features hidden while the team
finishes moderation, reporting, blocking, account deletion, and privacy work.
```

## App Review Notes

Use this as the starting point for Beta App Review or full App Review notes.
Edit it for the exact submitted build.

```text
SAVI is an iPhone-only private-save app for saving links, screenshots, PDFs,
images, videos, notes, and files from the iOS Share Sheet into a searchable
personal library.

Key flows to review:
- Launch the app and complete onboarding.
- Use the Share Sheet from Safari/Photos/Files/YouTube to save into SAVI.
- Open SAVI to browse Home, Search, Explore, Folders, and Profile.
- Try Private Vault/Face ID lock behavior.
- Export a full local archive from Profile/Backup.
- Restore a full local archive only after reviewing the restore preview.

Social/public features are intentionally hidden in this Release/TestFlight
build. The app may mention Social Beta as coming soon, but users cannot publish
public links, add friends, like, comment, message, or access a public feed in
this submitted build.

The sample library is removable and exists so testers can understand the app
without starting from an empty state. Health-related sample links are saved
research/reading examples and are not medical advice or treatment claims.
```

## Screenshot Storyboard

Use screenshots that show the app working, not marketing-only screens:

1. Onboarding: `Save it now. Find it later.`
2. Share Sheet setup: SAVI pinned and ready.
3. Share extension: folder and tag suggestion visible.
4. Home: mixed sample saves with strong thumbnails.
5. Search: query/refine results.
6. Folders: Private Vault, Life Admin, Recipes, Memes, Health.
7. Item detail: link/document/image preview and tags.
8. Profile/Backup: full archive export/import and Help & Feedback.

## Privacy Label Draft

This is not legal advice. Re-audit the exact build before submitting.
Use `Docs/Architecture/PrivacyDataInventory.md` as the living data inventory
before entering App Store Connect privacy answers.

For the current private-save-first build with no live Supabase/PostHog and no
public social:

- User content is stored locally/on-device and in user-selected exports.
- SAVI should not claim developer collection of private notes, screenshots,
  PDFs, files, or vault content unless a live backend/analytics SDK is enabled.
- Feedback email/TestFlight feedback may include contact information or
  screenshots only when the tester chooses to send them.
- Link metadata fetching may contact remote websites to load previews; do not
  describe this as developer collection unless routed through SAVI servers.

Before enabling accounts, Supabase, PostHog, push notifications, public social,
or iCloud backup, update:

- App privacy labels,
- privacy policy,
- in-app settings copy,
- account deletion behavior,
- App Review notes.

Required-reason API/privacy manifest audit:

- `Docs/Architecture/PrivacyManifestAudit.md`
- `scripts/savi-privacy-manifest-check.py`

App Store privacy-label answer packet:

- `Docs/Architecture/Runbooks/AppStorePrivacyLabels.md`
- `scripts/savi-appstore-privacy-labels-check.py`

For the current private-save-first build: No live Supabase/PostHog/APNs/social
collection in Release and no developer collection
of local saved content. Founder/legal must confirm whether optional
user-initiated support email should use the conservative support-disclosure
path.

Third-party SDK inventory:

- `Docs/Architecture/ThirdPartySDKInventory.md`
- `scripts/savi-sdk-inventory-check.py`

Sample content review:

- `Docs/Architecture/SampleContentReview.md`
- `Docs/Design/SampleLibrarySources.md`
- `scripts/savi-sample-content-check.py`

Before changing health hooks, meme/video examples, fake private documents, or
rabbit-hole sample links, rerun the sample-content check and keep the App
Review notes accurate: the library is removable, health cards are research
examples, and fake document cards use invented demo data.

## Export Compliance Draft

Current app posture appears to use only Apple platform security, HTTPS/TLS, and
standard system services. The app and share extension plists include
`ITSAppUsesNonExemptEncryption = NO`.

Use:

- `Docs/Architecture/Runbooks/AppStoreExportCompliance.md`
- `scripts/savi-appstore-export-compliance-check.py`

The founder/legal owner must still answer App Store Connect export compliance
truthfully for the exact submitted build.

## Social/UGC Release Gate

Do not expose public social until all of these are implemented and verified:

- Sign in with Apple/account path,
- in-app account deletion and Apple token revocation,
- explicit public web-link publishing only,
- no public private files/PDFs/screenshots/vault items,
- report flow,
- block flow,
- delete/unpublish flow,
- moderation workflow and support contact,
- App Store privacy labels updated,
- App Review notes updated,
- test account available if reviewers need social access.

## Final Human Checklist

- Privacy Policy URL is live.
- Support URL/email is live.
- Age rating answered in App Store Connect.
- `scripts/savi-appstore-age-rating-check.py` has passed for the submitted
  sample/social/browser/health posture.
- Export compliance answered by founder/legal owner.
- `scripts/savi-appstore-export-compliance-check.py` has passed for the
  submitted app/share-extension binary posture.
- Screenshots match current UI and iPhone-only portrait support.
- Share Extension real-device QA has passed on the exact build being submitted.
- Archive export/restore QA has passed on the exact build being submitted.
- Build number in App Store Connect matches the archive being submitted.
- Internal testers are assigned to the newest processed build.
- External TestFlight notes mention social is hidden/in progress.
- `scripts/savi-preflight.sh` passes.
