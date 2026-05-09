# SAVI App Store Connect Metadata

Use this as the copy-paste packet for App Store Connect and TestFlight. It is a
metadata runbook, not legal advice. Final privacy policy URL, support URL, age
rating, export compliance, screenshots, and legal/company details still need
founder approval before full App Store submission.

Run this checker before relying on this packet:

```bash
scripts/savi-appstore-metadata-check.py
```

## Current Build Context

- Version: `1.0`
- Current build: `34`
- Release app target: `SAVI`
- Release bundle ID: `com.altatecrd.savi`
- Share extension bundle ID: `com.altatecrd.savi.ShareExtension`
- Debug/internal bundle ID: `com.altatecrd.savi.personaldebug`
- Supported devices: iPhone
- Orientation: portrait
- TestFlight posture: private-save-first, social hidden
- Latest uploaded TestFlight build: `1.0 (34)`

## New App Record

| Field | Value |
|---|---|
| Platform | iOS |
| Name | `SAVI: Save Now, Find Later.` |
| Primary language | English (U.S.) |
| Bundle ID | `com.altatecrd.savi` |
| SKU | `savi-ios` |
| User Access | Full Access |

Use the app bundle ID, not the share extension bundle ID. The share extension
uses `com.altatecrd.savi.ShareExtension` and should not be selected as the main
App Store app record.

## App Information

| Field | Value |
|---|---|
| Primary category | Productivity |
| Secondary category | Utilities |
| Content rights | SAVI uses its own UI/artwork and saved-link previews that open to source sites; sample content is removable |
| Age rating | Founder must complete App Store Connect questionnaire |
| Pricing | Free for first beta unless changed later |
| Availability | Founder decision; default can be all supported App Store countries |

## Product Page Draft

| Field | Value |
|---|---|
| App name | `SAVI: Save Now, Find Later.` |
| Subtitle | `Save anything. Find it later.` |
| Promotional text | `Save links, screenshots, PDFs, videos, notes, files, and the little things you swear you will find again.` |
| Keywords | `save,organize,links,notes,files,pdf,screenshots,bookmarks,share sheet,search` |
| Support URL | `https://<your-domain>/support` |
| Privacy Policy URL | `https://<your-domain>/privacy` |
| Marketing URL | Optional for first beta |
| Copyright | Founder/company legal name |

Keyword budget note: the current keyword string is under Apple's 100-character
keyword field limit.

## Product Description Draft

```text
SAVI is a private pocket organizer for the useful things scattered across your
digital life: links, screenshots, PDFs, videos, Wi-Fi codes, files, notes,
places, recipes, research, and little ideas you may want again later.

Add SAVI to the iOS Share Sheet once, then save from Safari, YouTube, Photos,
Files, Messages, and the apps you already use. SAVI helps name each save, add
smart tags, choose a folder, and make it easy to search by title, note, tag,
folder, source, file type, or the tiny clue you remember.

Use SAVI for everyday things like travel codes, food recommendations, warranty
screenshots, research rabbit holes, private documents, recipes, videos, and
the links you would otherwise lose in a group chat.

This first beta is focused on fast saving, useful folders, strong search,
Private Vault, Explore for your own saved favorites, local archive backup, and
feedback. Social sharing is still in progress and is not active in this build.
```

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
5. Send feedback through TestFlight, directly to Andreus, or by email at
   1080solutionsA@gmail.com.

This build intentionally keeps public social features hidden while the team
finishes moderation, reporting, blocking, account deletion, and privacy work.
```

## App Review Notes

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

Social/public features are intentionally hidden in this Release/TestFlight
build. The app may mention Social Beta as coming soon, but users cannot publish
public links, add friends, like, comment, message, or access a public feed in
this submitted build.

The sample library is removable and exists so testers can understand the app
without starting from an empty state. Health-related sample links are saved
research/reading examples and are not medical advice or treatment claims.
```

## Screenshot Storyboard

1. Onboarding: `Save it now. Find it later.`
2. Share Sheet setup: SAVI pinned and ready.
3. Share extension: folder and tag suggestion visible.
4. Home: mixed sample saves with strong thumbnails.
5. Search: query/refine results.
6. Folders: Private Vault, Life Admin, Recipes, Memes, Health.
7. Item detail: link/document/image preview and tags.
8. Profile/Backup: full archive export/import and Help & Feedback.

## Age Rating Notes

Founder/legal must answer the App Store Connect age-rating questionnaire from
the exact submitted build. Use the dedicated age-rating packet before entering
answers:

- `Docs/Architecture/Runbooks/AppStoreAgeRating.md`
- `scripts/savi-appstore-age-rating-check.py`

Current product posture for the first beta:

- No gambling.
- No contests.
- No unrestricted web browser.
- No live public social feed in Release.
- No DMs or comments.
- No public user-generated PDFs, screenshots, files, or Private Vault content.
- Removable sample content includes saved-link previews and neutral health
  research examples, not medical advice.
- Medical/Treatment Information is founder/legal final because the sample
  library includes neutral health research links; answer conservatively if
  Apple's exact questionnaire wording treats those links as medical content.
- SAVI is not intended for the Kids category.

## Privacy And Legal Reminders

- Publish final `/privacy` and `/support` URLs before App Store submission.
- Use `Docs/Architecture/PrivacyDataInventory.md` before privacy-label answers.
- Founder/legal must confirm export compliance for the exact submitted build
  using `Docs/Architecture/Runbooks/AppStoreExportCompliance.md` and
  `scripts/savi-appstore-export-compliance-check.py`.
- If accounts, Supabase, PostHog, push notifications, or social go live later,
  update this metadata, privacy policy, privacy labels, and App Review notes.

## Final Human Replacements

Replace before full App Store submission:

- `https://<your-domain>/privacy`
- `https://<your-domain>/support`
- Founder/company legal name
- Final age-rating questionnaire answers
- Final export-compliance answer
- Final screenshots from the submitted build
