---
# 5ze-13f
title: Remove padding around app icon for macOS 26
status: in-progress
type: task
priority: normal
created_at: 2026-04-12T19:26:24Z
updated_at: 2026-04-12T19:50:51Z
sync:
    github:
        issue_number: "231"
        synced_at: "2026-04-12T20:23:25Z"
---

## Problem

On macOS 26, Apple introduced automatic icon composition (matching iOS) — the system applies a squircle mask and adds visual padding/insets around app icons. This makes the Swiftiomatic "S" icon appear smaller than intended in the Dock and elsewhere.

The current icon (`Xcode/SwiftiomaticApp/Assets.xcassets/AppIcon.appiconset/AppIcon.png`) is a full-bleed 1024×1024 square with the vintage metal plate "S" filling edge-to-edge. The system-imposed padding shrinks the visible content.

## Investigation Needed

- [x] Confirm whether `ASSETCATALOG_COMPILER_ICON_COMPOSITION` build setting exists in Xcode 26 to control padding behavior
- [ ] Check if providing a pre-composed icon (already squircle-cropped with transparent corners) bypasses automatic composition
- [ ] Test whether extending the icon artwork beyond the safe area (knowing edges will be clipped) reduces perceived padding
- [ ] Review Apple's HIG for macOS 26 icon specs — safe area insets, recommended content margins

## Possible Approaches

1. **Opt out of automatic composition** — if a build setting exists (e.g. `ASSETCATALOG_COMPILER_ICON_COMPOSITION = none`)
2. **Redesign icon to fill the safe area** — make the "S" and plate larger so it fills more of the visible area after masking
3. **Pre-crop to squircle** — supply an already-masked image so system padding is the only reduction
4. **Accept system padding** — if it's non-negotiable, at least ensure the icon artwork is optimized for the masked area

## References

- Apple docs: https://developer.apple.com/documentation/Xcode/configuring-your-app-icon
- Apple HIG: https://developer.apple.com/design/human-interface-guidelines/app-icons
- Current icon: `Xcode/SwiftiomaticApp/Assets.xcassets/AppIcon.appiconset/AppIcon.png`
- Current Contents.json: single 512×512@2x mac idiom entry
