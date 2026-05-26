---
# bcn-7lc
title: Evaluate SwiftLint rule improvements for Swiftiomatic analogues
status: completed
type: task
priority: normal
created_at: 2026-05-26T15:19:55Z
updated_at: 2026-05-26T15:27:39Z
sync:
    github:
        issue_number: "707"
        synced_at: "2026-05-26T15:33:26Z"
---

Three upstream realm/SwiftLint rule improvements (2026-05-24/25) may have analogues in Swiftiomatic worth porting:

- a6c4fccb — Surface `prefer_self_in_static_references` violations inside extensions (#6639)
- 6c55e0ea — Extend `pattern_matching_keywords` to support more cases (#6534)
- 43ce7e25 — Fix `explicit_self` false positives around string interpolation (#6662)

## Tasks
- [x] Check whether Swiftiomatic has analogues to each rule
- [x] For each analogue, evaluate whether the upstream change applies
- [x] File focused follow-up issues / fixes where relevant

Ref: realm/SwiftLint main

## Summary of Changes

**1. `prefer_self_in_static_references` (#6639)** — No analogue in Swiftiomatic (we have no rule that prefers `Self` over the type name in static contexts). The upstream change only matters if we add such a rule. No action; could be a future feature if desired.

**2. `pattern_matching_keywords` (#6534)** — Analogue is `HoistCaseLet`, which is already richer (a rewriter, not lint-only) and covers switch / if-guard-while-case / for-case patterns including tuples and nested enum associated values. Verified one real gap: it does **not** hoist `catch`-clause patterns (`catch Pattern.error(let x, let y)` was left unchanged). Filed follow-up **ukr-bwj**.

**3. `explicit_self` interpolation false positives (#6662)** — SwiftLint's `explicit_self` is the *inverse* of our `DropRedundantSelf` (it requires `self.`; we remove redundant `self.`). The fix was a SourceKit→SwiftSyntax migration. Verified `DropRedundantSelf` handles string interpolation correctly: `"Hello \(self.name) and \(name)"` → `"Hello \(name) and \(name)"` with no false positive. No action needed.
