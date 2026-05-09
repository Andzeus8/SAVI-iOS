# SAVI App Store Age Rating Packet

Use this packet when answering the App Store Connect age-rating questionnaire
for the current private-save-first SAVI build. It is not legal advice. The
founder/legal owner must answer the exact questionnaire shown in App Store
Connect for the submitted build.

Run this checker after editing age-rating, App Store metadata, or social
release posture docs:

```bash
scripts/savi-appstore-age-rating-check.py
```

## Source Anchors

- Apple: [Set an app age rating](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating)
- Apple: [Age ratings reference](https://developer.apple.com/help/app-store-connect/reference/age-ratings/)
- Apple: [App Review Guidelines, including UGC moderation](https://developer.apple.com/app-store/review/guidelines/)

Apple generates the rating from App Store Connect questionnaire answers. The
questionnaire includes content descriptors, in-app controls, and capabilities.
An app can also be manually overridden to a higher rating when the founder or
legal owner wants extra caution.

## Current Submitted-Build Posture

Use this section as the factual baseline before answering:

- SAVI is an iPhone-only, portrait-only private-save app.
- The app saves user-chosen links, screenshots, PDFs, images, videos, notes,
  audio, text, and files into a searchable personal library.
- The Share Extension receives user-selected content from other apps.
- Saved web links can open back to Safari or the source provider.
- SAVI does not provide a general web browser, address bar, search engine, or
  unrestricted web access surface.
- Release/TestFlight social is hidden: No live public social feed, no friend
  adding, no public publishing, no likes, no comments, and no DMs.
- No public user-generated PDFs, screenshots, files, documents, or Private
  Vault content are exposed in this build.
- Sample content is removable and exists only to demonstrate the app.
- Health sample cards are neutral research/reading saves and questions for a
  doctor, not medical advice, diagnosis, or treatment claims.
- The app has no gambling, no contests, no loot boxes, no ads, and no in-app
  purchases in the current release posture.
- The app is not intended for the Kids category.

## Recommended Answer Posture

Answer based on the exact App Store Connect wording shown at submission time.
This table gives the current SAVI stance and the caution notes to keep nearby.

| Questionnaire Area | Current SAVI Posture | Notes |
|---|---|---|
| Contests | No contests | SAVI does not run contests, sweepstakes, rewards, or promotions. |
| Gambling | No gambling | No real gambling, simulated gambling, betting, casino mechanics, or loot boxes. |
| Unrestricted Web Access | No unrestricted web browser | SAVI can open user-saved links externally, but it is not a browser/search engine and does not expose arbitrary browsing as an in-app capability. |
| User Generated Content / Social Networking | No live public social/UGC in current Release | Personal local saves exist, but public feeds, publishing, likes, comments, DMs, friend adding, and social browsing are hidden. Re-answer before social ships. |
| DMs / chat / messaging | No | SAVI does not include direct messaging or chat. |
| Public files / public documents | No | Public PDFs, screenshots, private files, and vault items are explicitly blocked from the planned social V1. |
| Medical/Treatment Information | Founder/legal final | Current health examples are saved research notes, not medical advice. If Apple wording treats health research links as medical/treatment information, answer conservatively for the submitted sample set. |
| Drugs, alcohol, tobacco | No app-provided promotion | Do not add drug/alcohol/tobacco sample content without re-rating. |
| Violence / horror / gore | No app-provided content | Do not add violent/horror/gore sample content without re-rating. |
| Sexual content / nudity | No app-provided content | Do not add sexual/nudity sample content without re-rating. |
| Profanity / crude humor | No app-provided profanity | Keep meme/sample titles clean for first submission. |
| Ads | No ads | Revisit privacy labels and rating posture if ad SDKs or marketing SDKs are added. |
| Kids category | Not intended for Kids | Do not select Made for Kids unless SAVI is redesigned for that program's stricter rules. |
| Age override | Founder/legal final | If there is uncertainty around health/rabbit-hole examples, the founder may choose to override higher for caution. |

## Suggested App Review Explanation

Use this language in App Review notes if the age-rating answers need context:

```text
SAVI is a private save-and-search app. It stores user-selected content locally
and lets users open saved links back to their source apps or Safari. It is not
an unrestricted web browser and does not include a public feed, public user
content, comments, direct messages, contests, gambling, or ads in this build.

The sample library is removable. Health-related sample links are framed as
research/reading examples and questions for a doctor, not as medical advice,
diagnosis, or treatment claims.
```

## Future Changes That Trigger Re-rating

Re-run this packet and update the App Store Connect age rating if any of these
ship in Release or external TestFlight:

- Social/UGC: public profiles, public publishing, friend feeds, likes,
  comments, DMs, public collections, user-submitted public files, or public
  screenshots.
- Moderation changes: reports, blocks, admin review, public visibility, or
  content deletion changes that alter what users can see.
- Browser-like features: in-app URL bar, general web search, open browsing,
  embedded web directory, or unrestricted web access.
- Medical/Treatment Information: stronger health claims, health integrations,
  treatment recommendations, symptom checkers, medical triage, or sample cards
  that could be read as advice.
- Mature sample content: profanity, crude humor, sexual content, nudity,
  violence, gore, horror, gambling, alcohol, tobacco, drugs, or weapons.
- Kids positioning: any attempt to enter the Kids category.
- Monetization: ads, ad SDKs, loot boxes, contests, or chance-based rewards.

## Final Founder Checklist

- Confirm the exact submitted build still matches the current posture above.
- Confirm sample content has not added mature, medical-claim, or social-public
  material since this runbook was updated.
- Run `scripts/savi-sample-content-check.py`.
- Run `scripts/savi-appstore-age-rating-check.py`.
- Answer the App Store Connect questionnaire from the current build facts, not
  future roadmap features.
- Save a screenshot/PDF of the final questionnaire answers in the private
  company records if desired. Do not commit private Apple account screenshots
  with personal account information.
