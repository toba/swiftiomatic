---
# 8cr-w0c
title: noMutableCapture flags explicit [var] capture lists, which are the correct Swift 6 idiom
status: completed
type: bug
priority: normal
created_at: 2026-05-02T01:47:02Z
updated_at: 2026-05-02T01:56:28Z
sync:
    github:
        issue_number: "622"
        synced_at: "2026-05-02T01:58:49Z"
---

## Problem

`noMutableCapture` fires on **explicit capture lists** (`[varName]`) of `var`-declared variables. The diagnostic message says:

> captured variable 'X' is declared with 'var'; closure captures the value at creation time, not subsequent mutations

But an **explicit** capture list is precisely how Swift expresses "snapshot the value now" — that's the intended semantic, not a bug. Flagging it makes the rule misfire on correct, idiomatic Swift 6 concurrency code.

## Reproduction

In a downstream project (Thesis), enabling `"noMutableCapture": { "lint": "error" }` produced 35 errors, all of the same shape, all legitimate. Representative cases:

```swift
// 1. Sendable hand-off across isolation (required by Swift 6 strict concurrency)
var groupID = ...
sqlite.read { [groupID] in try Node.fetch(for: groupID, from: $0) }

Task { [changes] in
    try await db.write { try CloudPendingChange.insert { changes.map(...) }.execute(db) }
}

Task.detached(priority: .background) { [sqlite] in
    try? await AppDatabase.runFullTextOptimization(on: sqlite)
}

// 2. Property-wrapper / @State cancellation closures
return FetchSubscription { [store] in
    MainActor.assumeIsolated { store.cancel() }
}

// 3. defer block snapshotting locally-mutated vars inside a lock
var missingTable: CKRecord.ID?
var missingRecord: CKRecord.ID?
var sentRecord: CKRecord.ID?
defer {
    state.withLock { [missingTable, missingRecord, sentRecord] in
        if let missingTable { ... }
    }
}

// 4. Test fixtures
var ref = try #require(references.first { !$0.wasDeleted })
ref.collectionKeys = []
try await db.write { [ref] in try ref.save(in: $0) }
```

In every case the var is mutated locally and then explicitly snapshotted via `[name]`. The "fix" the rule implies (make it `let`) is impossible because the variable is mutated; the alternative (drop the capture list) reintroduces capture-by-reference, defeating the Sendable hand-off.

## Suggested fix

Invert the semantics of the rule:

- **Flag implicit captures** of `var` locals (no capture list) — that is the actual footgun, since the closure silently observes/holds the mutable binding.
- **Exempt explicit `[var]` capture lists** — they are the documented remedy and are required for `Sendable` boundary crossing in Swift 6.

If the linter cannot reliably distinguish implicit vs explicit captures from the syntax tree, the rule should default to `warn` rather than `error`, since it produces false positives on correct concurrency code.

## Environment

- Project: Thesis (Swift 6.3, strict concurrency)
- swiftiomatic config: `"closures": { "noMutableCapture": { "lint": "error" } }`
- 35 errors emitted, 0 true positives observed



## Summary of Changes

Inverted `NoMutableCapture` semantics so it no longer flags the documented Swift 6 idiom for value-snapshot capture.

- **Before**: flagged every explicit `[varName]` capture list entry whose name matched a file-level `var` — i.e., flagged the very pattern Swift 6 strict concurrency requires for `Sendable` hand-off across isolation boundaries.
- **After**: flags *implicit* references to a file-level `var` from inside a closure body. Explicit capture lists, capture parameters, closure parameters, and locally-declared bindings shadow the outer `var` and exempt the closure.

Implementation in `Sources/SwiftiomaticKit/Rules/Closures/NoMutableCapture.swift`:

- Visit `ClosureExprSyntax`. Build a `shadowed` set from the capture clause, parameter clause, and locally-declared bindings (using a scope-aware collector that skips nested closures and type decls).
- Walk the body via `ImplicitCaptureFinder` (skips nested closures and trailing names of `MemberAccessExpr` so `self.counter` isn't flagged), and emit a finding for each `DeclReferenceExpr` whose name matches a file-level `var` and isn't shadowed.
- Default severity downgraded from `.error` to `.warn`.
- New diagnostic message: "closure implicitly captures mutable variable 'X'; add it to the capture list (`[X]`) to snapshot the current value, or rename to avoid collision".

Tests rewritten in `Tests/SwiftiomaticTests/Rules/NoMutableCaptureTests.swift` (12 cases): explicit `[var]` captures, `Sendable` hand-off shapes from the bug report, member access, parameter/local shadowing, and nested-closure scope isolation are all exempt; implicit references and multi-name closures are still flagged. Full suite: 3183/3183 passing.
