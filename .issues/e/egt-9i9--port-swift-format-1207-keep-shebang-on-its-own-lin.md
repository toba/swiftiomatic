---
# egt-9i9
title: 'Port swift-format #1207: keep shebang on its own line in SortImports'
status: completed
type: bug
priority: normal
created_at: 2026-06-19T15:35:18Z
updated_at: 2026-06-19T15:38:26Z
sync:
    github:
        issue_number: "736"
        synced_at: "2026-06-19T15:40:34Z"
---

Upstream swift-format commit 95ed8b4 (PR #1207, fixes #1194) restores a shebang line's trailing newline after reordering imports. Our SortImports.visit(_:) is the pre-fix form and drops the shebang's leading newlines, pulling the file header/first import up onto the shebang line.

- [x] Add reproducer tests (shebang + file header + import; shebang + reordered imports)
- [x] Port the shebang-newline restoration into SortImports.visit(_:)
- [x] Confirm tests pass


## Summary of Changes

Ported upstream swift-format #1207 into `SortImports`:

- `SortImports.visit(_:)` now restores the shebang's leading newlines after reordering, gated on `node.shebang != nil` and a `leadingNewlineCount` before/after comparison (mirrors upstream `OrderedImports`).
- Added private free function `leadingNewlineCount(of:)`.
- Added tests `shebangWithFileHeaderAndImport` and `shebangWithReorderedImports` to `SortImportsTests`.

Filtered suite green (32 passed).
