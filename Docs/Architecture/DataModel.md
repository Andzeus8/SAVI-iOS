# SAVI Data Model

This document describes the portable model vocabulary. iOS, future Android,
Supabase, analytics, and Founder Hub should use these concepts consistently.

## Core Item

A saved item is the central object.

Required fields:

- stable `id`,
- `title`,
- `createdAt`,
- `updatedAt`,
- `folderId`,
- `type`,
- `source`,
- `tags`,
- `isPrivate`,
- `isArchived`,
- `isDemo`.

Common metadata:

- canonical URL,
- display URL/domain,
- thumbnail URL or local thumbnail data,
- MIME type,
- asset name/file reference,
- metadata provider status,
- folder confidence,
- manual title/folder/tag override flags.

## Item Types

Canonical item types should stay platform-neutral:

- `link`
- `video`
- `image`
- `screenshot`
- `audio`
- `note`
- `pdf`
- `file`
- `place`

If the UI needs friendlier labels, map them at the UI layer.

## Folders

Folder IDs are migration-sensitive. Visible names can change, but IDs should
stay stable.

Default folder concepts:

- Life Admin,
- Private Vault,
- Watch / Read Later,
- AI & Work,
- Memes & LOLZ,
- Places & Trips,
- Recipes & Food,
- Notes & Clips,
- Research & PDFs,
- Design Inspo,
- Health,
- Science Finds,
- Rabbit Holes,
- Everything Else.

`Everything Else` remains the low-confidence fallback. `Private Vault` is only
for genuinely sensitive/private material.

## Public Social Link

Public social V1 only publishes web links the user explicitly marks public.

Allowed:

- title,
- canonical URL,
- domain,
- public thumbnail URL,
- public caption,
- owner profile ID,
- created/published timestamps,
- like count/report state.

Forbidden:

- PDFs,
- screenshots,
- private files,
- private vault records,
- local document names,
- note bodies unless a later public-note product is designed.
