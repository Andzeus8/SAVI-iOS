# SAVI Change Log

This log is the human-readable companion to git history. Git commits remain the
source of truth; daily entries summarize product intent, affected screens, build
targets, and QA evidence.

## 2026-05-05

- Polished Profile/Settings around a clearer SAVI Beta explanation, a setup
  checklist, cleaner management hierarchy, and more honest Social Beta
  coming-soon copy.
- Added a V22 sample-library and Folder Intelligence pass with an A/C warranty
  screenshot sample, stronger audio/sample file typing, screenshot OCR in the
  share extension, and Life Admin vs Private Vault guardrails.
- Recurated the launch sample library to keep the first six utility saves, then
  add more memorable memes, rabbit holes, science, recipes, and AI examples.
- Expanded `Memes & Laughs` and `Rabbit Holes` so Home, Explore, and Search feel
  more entertaining during first-run sample browsing.
- Moved Rick Astley/Rickroll into the first Home scroll and converted classic
  meme saves to real YouTube links with remote video thumbnails where stable
  video IDs were verified.
- Replaced the last generic meme-video placeholder with a direct `Chocolate
  Rain` YouTube save and remote YouTube thumbnail.
- Reframed the fasting sample as `Intermittent fasting and cancer: cure?` with
  safer research-note copy instead of a treatment claim.
- Replaced the early TED procrastination slot with a fuller problem-solving AI
  prompt and added stretching/core mobility plus perpetual-motion rabbit-hole
  samples.
- Moved Private Vault to the first sample folder position, made demo-only vault
  content visible before opt-in, and added a one-time Face ID/passcode prompt
  when users first open it.
- Expanded Private Vault samples with driver license, insurance, membership ID,
  routing number, tax PIN, and recovery-code examples using stronger full-card
  generated thumbnails.
- Simplified generated sample video thumbnails so Explore cards no longer show
  duplicate baked-in title text under the card overlay.
- Shortened the Home search launcher hint so it fits cleanly on iPhone SE.
- Started final TestFlight prep and removed the unused legacy web prototype
  `index.html` from the Release app resource bundle.
- See [2026-05-05](ChangeLog/2026-05-05.md).

## 2026-05-04

- Locked the two-channel naming rule: `SAVI` is Release/TestFlight with Social
  off, and `SAVI Test` is Debug/internal development with Social on.
- Added the TestFlight launch sample library and V4 refresh: clearer default
  folder names, the new `Life Admin` folder, 70 removable utility-first sample
  saves, and visible `Clear sample saves` controls.
- Fixed sample-library recovery so an empty cleared beta library can reload the
  samples once, while manual sample restore preserves personal saves.
- Polished folder tile readability while preserving the colorful card palette.
- Removed the need for a third `SAVI Pilot` channel for now.
- Refreshed both simulator installs from the current source tree.
- See [2026-05-04](ChangeLog/2026-05-04.md).

## 2026-05-03

- Tightened Explore so the page is simply `Explore`, with compact copy,
  smaller controls, and the existing mosaic shown sooner.
- Reworked the Folder editor into clearer collapsible sections and fixed the
  built-in Folder color-save bug.
- Polished Home's Recent Saves timeline into a continuous editorial rail with
  folder-colored item dots.
- Brought Search into the same editorial system: fluid timeline for recent
  browsing, compact relevance rows for active searches.
- Restored default Folders to a broader colorful palette and remapped prior
  lavender-heavy experimental defaults.
- Aligned Search, Explore, and the share extension: keyboard hides the bottom
  bar, Search has a compact header again, Explore is tighter, and sharing has a
  visible folder quick rail.
- Upgraded the share sheet Smart Tags into a folder-aware quick rail with
  automatic platform/type tags and common save-intent suggestions.
- Polished Search again with a clearer `Find everything.` header, slimmer
  search field, lighter type chips, and cleaner Refine/Clear controls.
- Added a simulator sync helper so `SAVI Test` and main `SAVI` can be built and
  installed from the same source pass without drifting.
- Added a simulator data clone helper so `SAVI Test` can mirror main `SAVI`'s
  folders, timeline, saves, and Home layout during QA.
- Updated Search copy to `Find the thing.` with a more playful SAVI-style
  support line.
- See [2026-05-03](ChangeLog/2026-05-03.md).

## 2026-05-02

- Started native SAVI version-history workflow and daily engineering ledger.
- Reconstructed the May 2 Search/Home work from current source, file mtimes,
  screenshots, and chat context because no git commits were made that day.
- See [2026-05-02](ChangeLog/2026-05-02.md).

## Future Entry Rule

Every meaningful SAVI task should add or update a dated file in `Docs/ChangeLog/`
with:

- Summary of the product change.
- Affected screens or flows.
- Files or subsystems touched.
- Build target used for QA, such as `com.savi.app` or the personal debug bundle.
- Screenshots, logs, or simulator/device notes when relevant.
