---
# 00a-95s
title: sm update command doesn't respect sort order
status: completed
type: bug
priority: normal
created_at: 2026-04-26T17:06:46Z
updated_at: 2026-04-26T17:15:28Z
sync:
    github:
        issue_number: "449"
        synced_at: "2026-04-26T18:08:48Z"
---

When `sm update` adds new rules to a local config (`swiftiomatic.json`), the inserted rules are alphabetical instead of following the configured sort order (e.g., length).

Recently added a batch of rules to local config and they came out alphabetical rather than sorted by length like the rest of the file.

Not critical — if the fix adds significant complexity, skip it. The config still works correctly; it's just a cosmetic/consistency issue.

## Repro
1. Have a `swiftiomatic.json` with rules sorted by length
2. Run `sm update` (or whatever command adds new rules to local config)
3. Observe new rules are appended/inserted in alphabetical order instead of by length

## Expected
New rules should be inserted respecting the existing sort order of the rules section.



## Summary of Changes

Fixed `Configuration.applyUpdateText` in `Sources/SwiftiomaticKit/Configuration/Configuration+UpdateText.swift` to place new keys in length+alpha-sorted position among existing siblings, instead of always appending at the end of the group.

- Refactored `insertion(into:source:items:indent:)` to bucket new items by their length+alpha predecessor among existing members and emit one `TextEdit` per bucket. Trailing-comma management adapts: only the bucket that becomes the new container tail strips its final comma.
- Extracted `lengthLess(_:_:)` helper mirroring `JSONValue.serialize(sortBy: .length)` so the comparator lives in one place.
- `createGroupEdit` now sorts items by length+alpha when seeding a brand-new group.
- Added 5 tests in `ConfigurationUpdateTextTests`: middle insertion, before-first, after-last (regression), multi-insert interleaving, and new-group child sort.

All 12 ConfigurationUpdateTextTests pass. Existing 29 failures elsewhere in the suite are unrelated (closure/layout/schema work in flight).
