---
# uh3-7g0
title: useSwiftTestingNames + dropRedundantBackticks conflict on single-word @Test funcs
status: completed
type: bug
priority: normal
created_at: 2026-06-03T04:59:49Z
updated_at: 2026-06-03T05:03:44Z
sync:
    github:
        issue_number: "719"
        synced_at: "2026-06-03T05:04:49Z"
---

## Symptom

Running `sm format -i` on a Swift Testing file with a single-word `@Test` func name like:

```swift
@Test func insert() async throws { … }
```

…rewrites it to:

```swift
@Test func `insert`() async throws { … }
```

`sm lint` then flags the same site with **two** competing rules:

- `[useSwiftTestingNames]` at the declaration — "rename '@Test' function 'insert' to raw identifier '`insert`'"
- `[dropRedundantBackticks]` at every call site — "remove unnecessary backticks around 'insert'"

The backticks around a non-keyword identifier are semantically a no-op (`` `insert` `` ≡ `insert`), so the formatter's rewrite is pointless and produces a self-inconsistent lint state — you can satisfy one rule or the other but not both.

## Reproduction

Across the Thesis test targets (109 files), a single `sm format` pass added 240 useless backtick pairs, immediately flagged by 240 paired `dropRedundantBackticks` warnings — the file sets are identical.

```sh
# Before formatting: 2145 useSwiftTestingNames, 21 dropRedundantBackticks
# After  formatting:  240 useSwiftTestingNames, 240 dropRedundantBackticks  (109 identical files)
```

Example:

```swift
@Test func `insert`() async throws {   // ← useSwiftTestingNames still fires here
    let selection = try await Self.insert(…)  // ← dropRedundantBackticks fires on call site
}
```

## Expected behaviour

`useSwiftTestingNames` should **not** fire when the proposed raw identifier is identical to the existing identifier (i.e. no whitespace or other characters that actually require backticks). For single-word test names, either:

1. Skip the rule entirely (the test name is already a valid Swift identifier and humanising it would be a content decision, not a formatting one), or
2. Surface a different message suggesting a more descriptive multi-word name, without auto-rewriting to a no-op `` `name` ``.

The formatter must not add backticks around bare identifiers that `dropRedundantBackticks` will then ask to be removed.

## Context

Discovered while working through `dyt-le8` in `toba/thesis` (project-wide `sm lint` cleanup). The mechanical formatter pass cleared 1905 of 2145 useSwiftTestingNames warnings; the remaining 240 are all this single-word case and cannot be auto-fixed without making the lint state worse.



## Summary of Changes

In `.rawIdentifier` style, `UseSwiftTestingNames` now leaves single-word `@Test` function names alone. The previous behaviour rewrote `@Test func insert()` → `` @Test func `insert`() ``, which `dropRedundantBackticks` immediately flagged at every call site — a self-inconsistent lint state that could not be auto-resolved.

Fix: after splitting the identifier into words and joining with spaces, skip the rewrite when the resulting `phrase` contains no space. Backticks around a bare identifier are a no-op, so wrapping single-word names just churns the source.

- `Sources/SwiftiomaticKit/Rules/Testing/UseSwiftTestingNames.swift` — early-return in `rawIdentifierTransform` when `phrase` has no space.
- `Tests/SwiftiomaticTests/Rules/UseSwiftTestingNamesTests.swift` — new `rawIdentifierLeavesSingleWordNamesAlone` test covering `insert` / `lookup`.
