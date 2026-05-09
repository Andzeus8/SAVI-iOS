# SAVI Reference Home Redesign Archive

- Timestamp: 2026-05-02 12:26:50 +0200
- Branch: main
- Latest commit: 0d5182b
- Purpose: Exact pre-redesign source copies for the reference-guided Home redesign pass.

## Archived Files

- `SAVI/Views/Home/HomeScreen.swift`
- `SAVI/Views/Items/ItemViews.swift`
- `SAVI/Views/Root/NativeSaviRootView.swift`
- `Docs/ChangeLog/2026-05-02.md`

## SHA-256 Checksums

```text
45c02e9ba8667884852481b13387a80c0f40a88c3119fab8823ab4889e077015  SAVI/Views/Home/HomeScreen.swift
1258368d05e500c23bde7a6571f46d271fb5d1087611557167fd916c99f856e7  SAVI/Views/Items/ItemViews.swift
98b47e1b057dd29c7ac4a2208b3a299a4a7950dc53a6150f52b528cfd3267b75  SAVI/Views/Root/NativeSaviRootView.swift
1e6fabcbda7cfffad42fe170881dd2ff7b82f7b5e35bb1b0dc66e56e9fb4372b  Docs/ChangeLog/2026-05-02.md
```

## QA Screenshots

- Before: `/Users/guest1/Desktop/SAVI_QA/home_before_2026-05-02-reference-redesign.png`
- After light: `/Users/guest1/Desktop/SAVI_QA/home_after_2026-05-02-reference-redesign.png`
- After quick theme check: `/Users/guest1/Desktop/SAVI_QA/home_after_2026-05-02-reference-redesign-dark.png`

## Generated Patches

```text
962dbd22de8602ad26d1fb03d8d50497ce0853ddc1b9ec7382a611e8118b7727  home-reference-redesign-forward.patch
0d9e8512779473d6964ed1225c9536d4afbbbffa447a0342c5a20a6e7caaa878  home-reference-redesign-revert.patch
```

## Restore Notes

To revert only this reference Home redesign, copy the archived files back to their matching project paths, or apply the generated `home-reference-redesign-revert.patch`.
