# SAVI Folder Palette And Image Background Archive

- Timestamp: 2026-05-02 17:52:15 +0200
- Branch: main
- Latest commit: 0d5182b
- Purpose: Exact pre-pass source copies before softening folder cards and adding optional image-background folder styling.

## Archived Files

- `SAVI/Views/Components/AppComponents.swift`
- `SAVI/Views/Items/ItemViews.swift`
- `SAVI/Views/Folders/FolderComponents.swift`
- `SAVI/Views/Home/HomeScreen.swift`
- `SAVI/Views/Save/SaveAndEditSheets.swift`
- `SAVI/Core/SaviCore.swift`
- `Docs/ChangeLog/2026-05-02.md`

## SHA-256 Checksums

```text
5d627e944669fa353f499858fb4aabdbf3ab8532ea39009fa1c351d2f8fde003  SAVI/Views/Components/AppComponents.swift
85a08c0176d649b32d5c39a599b6f2658d23b9fccee8cddcee8b655241d3777a  SAVI/Views/Items/ItemViews.swift
b77db5c2fd2d07c77e012e3fea349613f3a235134d0124fee34e5d5161cd1eb0  SAVI/Views/Folders/FolderComponents.swift
55ab6fe5609f4cf35c619cec3a398bd0a707ba9da1cba5fd0faab850e78104a5  SAVI/Views/Home/HomeScreen.swift
cd9116da1cf9a3dafe31fbc4db6cb7eddd3b4a150fdfed88518ce98d01cf32ca  SAVI/Views/Save/SaveAndEditSheets.swift
e6fed987420c76d891b0219130e11514b4a96c15ee8ebd1e2711370b57077c4d  SAVI/Core/SaviCore.swift
fe9d00d8242f74271718ec54eecba463993dae0eee993a877d92afbf414dc9be  Docs/ChangeLog/2026-05-02.md
```

## Restore Notes

To revert only this folder polish pass, copy the archived files back to their matching project paths, or apply the generated `folder-palette-image-background-revert.patch` after implementation.

## Generated After Implementation

- Forward patch: `folder-palette-image-background-forward.patch`
- Revert patch: `folder-palette-image-background-revert.patch`
- Screenshot folder: `screenshots/`

## Patch And Screenshot SHA-256 Checksums

```text
2b0fd0afcc98fdddbd0aff61017e8e36d059f6564b6c4e2fc145a59131d06e82  folder-palette-image-background-forward.patch
ac6925784e3e0b80c4e5b22503b0f6dd1ae528ca129b185fbb2ddbf79af2a1e5  folder-palette-image-background-revert.patch
31c554f3e8c7400bae1aae787e131ea6950cd48c4b24ba93c552f38f7678111d  screenshots/home_after_folder_palette_soften.jpg
55ed7de65311179a3b2cb9a9f1769a6c0db57a4814053ffdba37365d55a9988f  screenshots/folders_after_folder_palette_soften.jpg
bea18e7a57253ec1a6157c62b4df040cb1504fab90eb5b6b7d79847c378a96cf  screenshots/folders_after_folder_palette_system_dark_check.jpg
```
