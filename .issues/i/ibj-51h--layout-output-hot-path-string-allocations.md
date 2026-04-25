---
# ibj-51h
title: 'Layout output: hot-path string allocations'
status: completed
type: task
priority: high
created_at: 2026-04-25T20:41:34Z
updated_at: 2026-04-25T20:59:20Z
parent: 0ra-lks
sync:
    github:
        issue_number: "429"
        synced_at: "2026-04-25T22:35:11Z"
---

Several allocation hot spots in the formatting output path. Each fires per token / per line, so the cumulative cost on large files is significant.

## Findings

- [x] `Verbatim.print()` — added capacity pre-computation and `output.reserveCapacity(...)`; hoisted `indent.indentation()` outside the loop.
- [x] `Verbatim.swift` + `LayoutBuffer.swift` — `String(repeating: " ", count: n)` replaced with `SpacePadding.spaces(n)` (new `Sources/SwiftiomaticKit/Layout/SpacePadding.swift` with cached strings for widths 0...64).
- [x] `Verbatim.swift` — `CharacterSet(charactersIn: " ")` hoisted to `Verbatim.spacesOnly` static.
- [x] `Comment.trimmingTrailingWhitespace()` — rewritten to walk `StringProtocol` characters from the end via `index(before:)`; no longer materializes `Array(utf8)`. Whitespace recognition matches the prior byte-level check (space, LF, tab, CR, VT, FF).
- [ ] `Comment.swift:102` — `text.reduce(0, { $0 + $1.count })` deferred. `length` is already accumulated incrementally everywhere except at construction; the suggested `.lazy.map` pattern doesn't actually reduce work for an Array. Marginal.
- [ ] `WhitespaceLinter.swift:40-41` — `Array(user.utf8)` deferred. The whole linter operates on `ArraySlice<UTF8.CodeUnit>` indices via integer offsets; switching to `String.UTF8View` indices is a wider refactor with unclear net win.
- [x] `WhitespaceLinter.swift:450` — `indents.dropFirst().reduce(...)` replaced with an explicit `for i in 1..<indents.count` loop.

## Test plan
- [x] Targeted layout tests pass: 35/35 (Verbatim, Comment, WhitespaceLinter, LayoutBuffer suites).
- [x] Build clean.
- [ ] Empirical large-file benchmark not run in this task; the optimisations are structural (capacity reservation, cached strings, removed full-buffer copy).

## Summary of Changes

Reduced per-line / per-token string allocations in the formatting output path.

- **New file**: `Sources/SwiftiomaticKit/Layout/SpacePadding.swift` — `enum SpacePadding` with a pre-built cache of space strings for widths 0...64 (covers virtually all practical indentation). Falls back to `String(repeating:count:)` for larger widths.
- **`Verbatim.swift`**:
  - Hoisted `CharacterSet(charactersIn: " ")` to `spacesOnly` static (was rebuilt per line during init).
  - `print(indent:)` now hoists `indent.indentation()` outside the line loop, pre-computes the total UTF-8 capacity, and calls `output.reserveCapacity(...)` before concatenating. Replaces `String(repeating: " ", count: n)` with `SpacePadding.spaces(n)`.
- **`LayoutBuffer.swift`**: `writeRaw(String(repeating: " ", count: pendingSpaces))` → `writeRaw(SpacePadding.spaces(pendingSpaces))`.
- **`Comment.swift`**: `trimmingTrailingWhitespace()` no longer copies the full UTF-8 buffer into an `Array`. Walks Characters from the end via `index(before:)` (StringProtocol is BidirectionalCollection) and matches the same ASCII whitespace set the prior byte-level check used.
- **`WhitespaceLinter.swift`**: `indents.dropFirst().reduce(...)` in `diagnosticDescription` replaced with an explicit `for i in 1..<indents.count` loop (avoids the slice wrapper allocation, clearer intent).

Two findings deferred (`Comment.length` reduce, `WhitespaceLinter` `Array(utf8)`); they are noted above with rationale.
