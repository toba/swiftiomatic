---
# 3eb-r8b
title: Remove .bridge() calls — use idiomatic Swift casts
status: completed
type: task
priority: normal
created_at: 2026-03-01T18:45:33Z
updated_at: 2026-03-01T18:48:35Z
sync:
    github:
        issue_number: "129"
        synced_at: "2026-03-01T21:06:29Z"
---

Replace all .bridge() call sites with idiomatic Swift: drop where String extensions exist, use `as NSString` for path ops, explicit casts for NSRange loops, .utf8.count for byte lengths.


## Summary of Changes

Replaced all 17 compiled `.bridge()` call sites across 11 files with idiomatic Swift:

- **Drop `.bridge()`** where String extensions already exist: `absolutePathStandardized()`, `fullNSRange` (3 sites)
- **`as NSString` casts** for path operations: `lastPathComponent`, `deletingPathExtension`, `appendingPathComponent` (7 sites)
- **Explicit `as NSString`/`as String` casts** in NSRange replacement loops: ExplicitSelfRule, UnusedImportRule (5 sites)
- **`.utf8.count`** replacing `.bridge().lengthOfBytes(using: .utf8)` (1 site)
- **`(x as NSString).replacingCharacters(in:with:)`** in SyntacticSugarRule (1 site)
- **Skipped** 2 occurrences in UnavailableFunctionRule — inside `Example("""...""")` string literals, not compiled code

All changes are zero-cost toll-free bridging. No functional behavior change.
