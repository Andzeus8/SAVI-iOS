# SAVI Analytics And Metrics

The source of truth for current event names is:

`/Users/guest1/Documents/SAVI-iOS/Docs/Backend/AnalyticsEventCatalog.md`

This file explains how those events should support product, investor, and
reliability decisions.

## Company Questions

SAVI analytics should answer:

- Are people opening the app repeatedly?
- Do they complete onboarding?
- Do they activate the share extension?
- Do saves complete successfully?
- Does metadata/folder intelligence work?
- Do users search and find things?
- Which item types and safe domains are most useful?
- Does social increase saving without creating moderation risk?
- Which devices/builds are slow or crashy?

## Missing Event To Add

Add a future event:

`saved_item_shared_out`

Purpose: track when a user opens or shares a saved item out of SAVI to another
app or destination.

Safe properties:

- item type,
- source group,
- folder category,
- public/private boolean,
- destination group if available,
- domain only for normal web links,
- app version/build,
- device tier.

Forbidden:

- destination contact,
- private note text,
- private file name,
- screenshot/OCR content,
- Private Vault content,
- raw URL for private/unpublished links.

## Dashboard Groups

- Pulse: DAU/WAU/MAU, sessions, build adoption.
- Share Sheet Rocket: share extension opened, save completed, metadata success.
- Save Engine: saves per user, item types, source groups, folder confidence.
- Search Brain: search usage, result-count buckets, zero-result rate.
- Rabbit Hole Radar: public domains and explicit public links only.
- Social Lab: follows, hearts, public saves, reports/blocks.
- Reliability Room: crashes, metadata failures, slow devices, save failures.
- TestFlight Room: tester/build adoption and known issues.
