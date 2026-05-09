# SAVI Compact Editorial Home Archive

- Timestamp: 2026-05-02 15:21:51 +0200
- Branch: main
- Latest commit: 0d5182b
- Purpose: Exact pre-redesign source copies for the compact utility header and editorial timeline Home pass.

## Archived Files

- `SAVI/Views/Home/HomeScreen.swift`
- `SAVI/Views/Items/ItemViews.swift`
- `SAVI/Views/Root/NativeSaviRootView.swift`
- `Docs/ChangeLog/2026-05-02.md`

## SHA-256 Checksums

```text
53100731560ceeb1282fb0656df0d882960c76f88e40d4f9fb9d36c09401dc14  SAVI/Views/Home/HomeScreen.swift
5ae1121d1531a395abbe8f6d0b3f075204e0adcc488506ec41d1d209fc00a467  SAVI/Views/Items/ItemViews.swift
6dcb64ec5cb0656774d4b622436b390f2882d9c5b692ffa0ac6540869586debd  SAVI/Views/Root/NativeSaviRootView.swift
761182ee7c75f26a7186c825e0f093ac388c8df5c4675c6c19230f541423ced7  Docs/ChangeLog/2026-05-02.md
```

## QA Screenshots

- Before: `/Users/guest1/Desktop/SAVI_QA/home_before_2026-05-02-compact-editorial.png`
- After light: `/Users/guest1/Desktop/SAVI_QA/home_after_2026-05-02-compact-editorial-light.png`
- After theme check: `/Users/guest1/Desktop/SAVI_QA/home_after_2026-05-02-compact-editorial-dark.png`
- Archived copies: `screenshots/`

## Patch Files

```text
052f67758b5b3d8aa0cd6fbf79c6c508ec2bb9a56a01a106bc4f69c16bd5a8cb  home-compact-editorial-forward.patch
b5b6786d3728d29d490de1dd4b15c8fa353fba7e7be54ddd4e0cfebabfaa720a  home-compact-editorial-revert.patch
```

## Screenshot Checksums

```text
cbb69987f3e0cb8481ed892b57093dcf5bf1ebd6408f9bcc7a7a778b95607eaa  screenshots/home_before_2026-05-02-compact-editorial.png
729d3434b4444845055112e518dea357957b7243e793830c97d56bef388212fe  screenshots/home_after_2026-05-02-compact-editorial-light.png
4c8dae81f6bc0b986193f73effc81b880eb28050c7d1656973151bbbbc1a97f2  screenshots/home_after_2026-05-02-compact-editorial-dark.png
```

## Restore Notes

To revert only this compact editorial Home pass, copy the archived files back to their matching project paths, or apply the generated `home-compact-editorial-revert.patch` after implementation.
