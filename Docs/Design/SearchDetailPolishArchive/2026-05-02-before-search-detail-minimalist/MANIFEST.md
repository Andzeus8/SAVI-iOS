# SAVI Search And Item Detail Minimalist Archive

- Timestamp: 2026-05-02 17:10:44 +0200
- Branch: main
- Latest commit: 0d5182b
- Purpose: Exact pre-polish source copies for the Search and item detail minimalist pass.

## Archived Files

- `SAVI/Views/Search/SearchScreen.swift`
- `SAVI/Views/Search/SearchComponents.swift`
- `SAVI/Views/Items/ItemViews.swift`
- `SAVI/Views/Save/SaveAndEditSheets.swift`
- `SAVI/Views/Home/HomeScreen.swift`
- `SAVI/Core/SaviCore.swift`
- `Docs/ChangeLog/2026-05-02.md`

## SHA-256 Checksums

```text
8643da5854278f990047f411888b496f726b5b0f0c14a59e48921f13e407abe8  SAVI/Views/Search/SearchScreen.swift
8704dc9c1f5388ee4fd417d95e2a81771c463a6c0743cd44f47cf5d6e91243c8  SAVI/Views/Search/SearchComponents.swift
4322aa2ac1cbce0a9f4003943cd3b54e683722ce9ad56b6f484c978fced5a875  SAVI/Views/Items/ItemViews.swift
b65f882007d28e3a51cf076156ea7f4b96f9f93e9ea62ef75f4ce743325eb13e  SAVI/Views/Save/SaveAndEditSheets.swift
64b4c27bbe6ba2b6c36bb695dec4fae33926305f22231c89253aabe5213a2114  SAVI/Views/Home/HomeScreen.swift
97d7c133a6e526bc1dcec0a7c9b0d49c6e42e5ffb6740a3562776f64b2bfa7e0  SAVI/Core/SaviCore.swift
90225906cf0a5427696fe5da0a60cfe99ffd8d254be6d32d3968baab6c09cce7  Docs/ChangeLog/2026-05-02.md
```

## Restore Notes

To revert only this Search/detail polish pass, copy the archived files back to their matching project paths, or apply the generated `search-detail-minimalist-revert.patch` after implementation.

## Generated After Implementation

- Forward patch: `search-detail-minimalist-forward.patch`
- Revert patch: `search-detail-minimalist-revert.patch`
- Screenshot folder: `screenshots/`

## Patch And Screenshot SHA-256 Checksums

```text
e5a1fdf94b81d9dedbbbf78e7a954ee31784aeabd4e277c7a45c0b927190b1bb  search-detail-minimalist-forward.patch
194733a00b36a7c474309b4e7265a0ad693c4482bbe3c3cf1b4afcefe114e634  search-detail-minimalist-revert.patch
47abe745b744f38da0f202f50937d7f1a7ab338e915517f24f59f5e330f16989  screenshots/home_after_search_detail_minimalist.png
85b216138adcf865a120652a316b134055ebc45c9f950177b1a61914ad754a59  screenshots/search_after_minimalist_default_optimized.jpg
0dea0b8556878459147907d98425febb4afb7154989db8b1c6beb828fba19858  screenshots/search_after_minimalist_filtered.png
aca3f5fdf2fda66eb0da1e82ff938594161a418c790b063bbd121e6188d1df01  screenshots/search_refine_after_minimalist_optimized.jpg
c10b8df90cbb8932c5e37725f7dc2634669bd05232d56bdf42c5408bd818f4a5  screenshots/item_detail_after_minimalist.jpg
```
