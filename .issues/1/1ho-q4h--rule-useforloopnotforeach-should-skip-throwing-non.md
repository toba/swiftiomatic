---
# 1ho-q4h
title: rule [useForLoopNotForEach] should skip throwing non-Sequence forEach (e.g. GRDB Cursor)
status: completed
type: bug
priority: normal
created_at: 2026-05-08T01:56:31Z
updated_at: 2026-05-08T02:00:33Z
sync:
    github:
        issue_number: "646"
        synced_at: "2026-05-08T02:54:16Z"
---

## Symptom

`useForLoopNotForEach` flags GRDB `DatabaseCursor.forEach`, which is **not** `Sequence.forEach`:

```swift
let cursor = try QueryValueCursor<From>(db: db, query: query)
var output: [From.QueryOutput] = []
try cursor.forEach { output.append($0) }  // flagged
```

`Cursor` (GRDB) is a single-pass iterator with `next() throws -> Element?` and a throwing `forEach`. It does not conform to Swift `Sequence`, so the rule's premise (rewrite to `for x in seq`) does not apply — `for x in cursor` does not compile.

## Detection (syntactic, no type info needed)

`Sequence.forEach` is declared `rethrows`. The call site only needs `try` if the closure throws. So:

- `try receiver.forEach { closure }` where the closure body contains **no** `try`/`throw` → the method itself throws unconditionally → it is **not** `Sequence.forEach` → skip the rule.
- `try receiver.forEach { ... try thing() ... }` → ambiguous (could be `Sequence.forEach` rethrowing, could be GRDB-style); leave the rule firing as-is, or downgrade to a softer hint.
- `receiver.forEach { ... }` (no `try`) → definitely `Sequence.forEach`; rule applies.

This is purely syntactic — works in a syntactic linter without resolver/type info.

## Repro

Thesis project, `Core/Sources/Storage/DSL/Statements/Statement.swift:59` and `:200`. Currently silenced with `// sm:ignore:next useForLoopNotForEach`.

## Acceptance

- `try cursor.forEach { append($0) }` does not fire `[useForLoopNotForEach]` when the closure body has no `try`/`throw`.
- `try seq.forEach { try x() }` continues to fire (or fires softer) — caller can decide.
- Existing test cases for the rule still pass.



## Summary of Changes

- `Sources/SwiftiomaticKit/Rules/ControlFlow/UseForLoopNotForEach.swift`: Skip the diagnostic when the call's parent is a `TryExprSyntax` and the trailing closure body contains no `try`/`throw`. Since `Sequence.forEach` is `rethrows`, an unconditional `try` with a non-throwing body cannot be `Sequence.forEach` (e.g. GRDB `Cursor.forEach`), and `for x in receiver` would not compile. Added a small `ClosureThrowScanner` that descends into nested closures so any `try`/`throw` anywhere keeps the rule firing (prefer false positives per project policy).
- `Tests/SwiftiomaticTests/Rules/UseForLoopNotForEachTests.swift`: Added `testSkipsThrowingNonSequenceForEach` covering the cursor-style skip plus still-firing ambiguous cases (`try` inside body, `throw` inside body).
- Filtered test pass; full suite (3224 tests) passes.
