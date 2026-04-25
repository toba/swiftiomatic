---
# hib-4ov
title: sm update rewrites entire swiftiomatic.json instead of editing
status: completed
type: bug
priority: high
created_at: 2026-04-25T18:58:58Z
updated_at: 2026-04-25T20:28:26Z
sync:
    github:
        issue_number: "410"
        synced_at: "2026-04-25T22:35:07Z"
---

## Problem

`sm update` decodes the configuration to `JSONValue`, mutates the dict, and re-encodes with `JSONEncoder(.sortedKeys)`. Two layered bugs:

1. `JSONValue.object` is `[String: JSONValue]` (unordered) — original key order is lost on decode.
2. Re-encoding with `.sortedKeys` then alphabetizes everything.

Net effect: a single rule add/remove rewrites the whole file in alphabetical order. Comments (JSON5) are also stripped.

## Approach

Surgical, mechanical text edits — no LLM. Keep `computeUpdate` (correct). Add a text-level applier that operates on the original source bytes:

- Tiny position-aware JSON5 scanner: top-level keys, group spans, trailing-comma context, comments preserved.
- Edits in right-to-left order: removals (delete key line + fix comma on prior sibling if last); misplaced (delete + splice raw value text at destination); additions (pretty-print default, splice before group's `}`).
- Placement: append at end of group (no reordering of existing keys). New groups appended at end of root.

## Tasks

- [x] Failing test: `sm update` preserves key order
- [x] Failing test: preserves a JSON5 line comment
- [x] Failing test: removes a key, fixes comma on previous sibling when removing last child
- [x] Failing test: misplaced rule: parsed value preserved at destination
- [x] Failing test: adds new rule appended at end of group
- [x] Failing test: creates a brand-new group when one is needed
- [x] Implement JSON5 scanner with key/value/group spans (token-stream design adapted from croct-tech/json5-parser-js)
- [x] Implement `Configuration.applyUpdateText`
- [x] Wire into `Update.run` (replace decode→re-encode path)
- [x] All tests green (32/32: 16 scanner, 6 text-applier, 10 dict-level)



## Summary of Changes

- New `Sources/SwiftiomaticKit/Configuration/JSON5Scanner.swift` — token-stream JSON5 scanner with `peek/next/consume/expect/matches/skipInsignificant`. Handles JSON5 keys (quoted + identifier), single/double-quoted strings, hex/Infinity/NaN/signed numerics, trailing commas, and `// /* */` comments. Design adapted from croct-tech/json5-parser-js (no dependency added).
- New `Sources/SwiftiomaticKit/Configuration/Configuration+UpdateText.swift` — surgical text-edit applier. Uses scanner spans to compute right-to-left text edits: removals delete the member's logical block (rebalancing the prior sibling's trailing comma when removing the last child); misplaced entries delete + splice; additions pretty-print using the existing `JSONValue.serialize(.length)` + small-object compaction style. Default placement: append at end of group; brand-new groups appended at end of root.
- `Sources/Swiftiomatic/Subcommands/Update.swift` — replaced the decode→`apply`→`JSONEncoder(.sortedKeys)` write path with `Configuration.applyUpdateText`. Removed the now-unused `extractRuleKeys`, `extractRuleValue`, `compactSmallObjects`, `compactObject` helpers.
- New `Tests/SwiftiomaticTests/API/JSON5ScannerTests.swift` (16 tests) and `ConfigurationUpdateTextTests.swift` (6 tests). Existing `ConfigurationUpdateTests` still pass — the dict-level diff path is unchanged.

## For Review

Manual verification needed: run `sm update` against your real `swiftiomatic.json` and confirm only the diff'd keys change (no reordering, no comment loss).
