# SAVI Sample Content Review

This is the safety review for SAVI's removable sample library. It exists
because the sample library intentionally has personality: useful private-save
examples, health research rabbit holes, famous internet videos, funny links,
fake documents, and practical screenshots. That mix is good for onboarding, but
it needs guardrails so it stays App Store-friendly and trustworthy.

Run this check after changing sample items, thumbnails, folder defaults, or
sample-source documentation:

```bash
scripts/savi-sample-content-check.py
```

## Current Position

- The sample library is removable sample library content, not user content.
- Sample items are demo saves that teach SAVI's value before a new user has
  saved anything.
- Real third-party links open back to their source site.
- Third-party video/meme thumbnails use remote provider metadata or provider
  thumbnail URLs, not bundled SAVI-owned media.
- Sensitive documents use generated fake sample art with invented demo data and
  visible `SAMPLE` markings.
- Health examples are framed as research, reading notes, or
  questions-for-doctor material, not medical advice.

## Health And Medical Guardrails

Health cards can be interesting and even provocative, but they must stay
research-framed.

Allowed:

- PubMed, NCI, CDC, NIH, Harvard Health, MedlinePlus, Red Cross, or similarly
  reputable sources.
- Titles that clearly read as questions or saved research hooks.
- Descriptions that say the item is a research note, clinician discussion, or
  questions-for-doctor save.
- Counterbalance items from reputable public-health sources near provocative
  cards.

Not allowed:

- Claims that a food, medication, supplement, parasite treatment, fasting, or
  lifestyle habit cures cancer.
- Claims that a sample is a proven treatment unless the linked source and the
  description both support that statement, and legal/medical review approves it.
- Medical instructions that look like SAVI is giving care advice.
- Health thumbnails or titles that imply certainty when the source is a case
  report, preprint, small trial, opinion piece, or hypothesis.

Current high-attention health samples:

- `Parasite medication and cancer remission?` links to a PubMed case report and
  says it is for doctor questions, not medical advice.
- `Intermittent fasting and cancer: cure?` links to PubMed and says it is for
  clinician discussion, not medical advice or a proven treatment.
- `Common Cancer Myths and Misconceptions` from NCI sits nearby as the safety
  counterbalance.
- `Does your microbiome control your thoughts?` is framed as a curiosity note,
  not medical advice.

## Media, Meme, And IP Guardrails

SAVI can show saved-link previews for famous internet videos. SAVI should not
bundle third-party videos, copyrighted stills, or famous meme photos as app
assets unless the license is clear and recorded.

Allowed:

- Real YouTube links that open to YouTube.
- Remote YouTube thumbnail URLs such as `https://img.youtube.com/vi/...` as
  saved-link previews.
- Live metadata for public links where possible.
- Original generated artwork or stock artwork with source/license recorded.

Not allowed:

- Bundled copies of YouTube thumbnails, celebrity images, famous meme photos,
  music videos, or video stills without permission.
- Fake metadata that makes a third-party link look like SAVI-created content.
- Famous copyrighted meme photos used as folder covers or bundled thumbnails.

Current meme/video sample posture:

- Rick Astley, Numa Numa, Charlie Bit My Finger, Skibidi Toilet, Dramatic Look,
  Badger Badger Badger, Keyboard Cat, Double Rainbow, Evolution of Dance, and
  Leave Britney Alone use real YouTube URLs and remote thumbnails.
- `Memes & LOLs` folder art uses generated original SAVI artwork, not a famous
  third-party meme photo.

## Fake Document And Private Vault Guardrails

Private Vault examples are important because they show SAVI's practical value.
They must never look like real personal data copied from a real person.

Required:

- Invented demo data.
- Visible `SAMPLE` marking or copy.
- No real government IDs, real insurance cards, real bank details, real medical
  records, or real passwords.
- No real person's full legal identity, birthday, address, member number, or
  account number.
- File names and descriptions should make it clear the item is a demo sample.

Current sensitive samples include fake insurance, fake driver's license,
membership ID, bank-routing note, passport checklist, birth certificate,
medical card, receipt, warranty, emergency recovery code, and Wi-Fi/password
examples. These must remain fake.

## Rabbit-Hole And Curiosity Guardrails

The rabbit-hole category should feel fun and surprising, not misleading.

Allowed:

- Official sources, archival sources, science museums, Britannica, Smithsonian,
  NASA, UNESCO, National Archives, and reputable explainers.
- Titles that frame the item as a curiosity or question.
- Copy that encourages fact-checking or saved reading.

Not allowed:

- Presenting conspiracy claims as verified fact.
- Fear-based claims without source context.
- Public-safety, financial, or medical claims without reputable sources.

## Source Tracking

Keep source/license notes in `Docs/Design/SampleLibrarySources.md`.

Every sample content change should answer:

- Is this a real public link, a generated sample, or a bundled stock image?
- If it is third-party media, are we linking to the source instead of bundling
  the media?
- If it is health-related, is it framed as research and not medical advice?
- If it looks private or official, is it invented demo data with `SAMPLE`
  markings?
- If it is a rabbit-hole item, is it sourced and framed as curiosity or
  fact-checking?

## Release Checklist

Before external TestFlight or App Store review:

- Run `scripts/savi-sample-content-check.py`.
- Run `scripts/savi-preflight.sh`.
- Confirm the sample library can be cleared.
- Confirm health examples still include not-medical-advice framing.
- Confirm real links open the source website.
- Confirm sensitive samples are fake and visibly marked.
- Confirm App Review notes still say sample content is removable and health
  links are saved research examples, not treatment claims.
