---
# 8n8-rby
title: Window title should show folder name, not .swiftiomatic.yaml
status: scrapped
type: bug
priority: normal
created_at: 2026-04-13T16:22:33Z
updated_at: 2026-04-14T02:54:38Z
sync:
    github:
        issue_number: "260"
        synced_at: "2026-04-14T02:58:29Z"
---

The window title currently shows `.swiftiomatic.yaml` for every open file, which is unhelpful since all config files share the same name.

**Expected**: Window title shows the parent folder name (e.g. `MyProject`) instead of the filename.

**Current**: Title bar says `.swiftiomatic.yaml` regardless of which project's config is open.

## Tasks

- [x] Find where the window title is set
- [x] Change it to use the parent directory name instead of the filename
- [x] Handle edge case where path has no meaningful parent (e.g. root)


## Summary of Changes

- Created `Xcode/SwiftiomaticApp/Views/WindowAccessor.swift` with a KVO-backed `ParentFolderTitleModifier` that persistently overrides the window title with the parent folder name
- Replaced the one-shot `.task` approach in `SwiftiomaticApp.swift` with `.parentFolderWindowTitle(fileURL:)` which survives DocumentGroup title reassertions
- Guards against edge cases: nil URL, root path, and KVO recursion
