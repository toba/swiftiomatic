---
# gxn-fyv
title: Integrate incremental parsing for IDE extension performance
status: ready
type: feature
priority: low
created_at: 2026-04-12T23:54:23Z
updated_at: 2026-04-12T23:54:23Z
parent: oad-n72
sync:
    github:
        issue_number: "249"
        synced_at: "2026-04-13T00:25:20Z"
---

swift-syntax supports incremental reparsing that reuses unchanged subtrees when source edits are small. Currently `SwiftSource.syntaxTree` caches the full parse per file — incremental reparsing would be faster for repeated lint-on-type in the editor extension.

## Reference

`SwiftParser/IncrementalParseTransition.swift`:
- `IncrementalParseTransition` — tracks previous parse result + edits
- `ConcurrentEdits` — non-overlapping source edits
- `IncrementalParseLookup` — O(1) lookups for reusable nodes by position and kind
- Callback mechanism to track which nodes were reused

## Tasks

- [ ] Investigate `IncrementalParseTransition` API surface
- [ ] Extend `SwiftSource` to accept previous parse result + edits
- [ ] Measure parse time improvement on typical edit-then-lint cycles
- [ ] Integrate with Xcode Source Editor Extension if measurable benefit
