---
# 3o6-ja3
title: 'Check: Fire-and-forget Tasks & .onAppear+Task (§8b, §8c)'
status: completed
type: task
priority: normal
created_at: 2026-02-27T21:35:50Z
updated_at: 2026-02-27T21:55:08Z
parent: 52u-0w0
blocked_by:
    - w7e-hbx
sync:
    github:
        issue_number: "81"
        synced_at: "2026-03-01T01:01:45Z"
---

SyntaxVisitor that detects unmanaged Task lifecycle issues.

## What grep does today (§8b, §8c)
- 8b: Finds `Task {` / `Task(priority:` lines where result isn't assigned (~40% false positive rate)
- 8c: Finds `.onAppear { ... Task { }` proximity via multiline regex (~5% false positive)

## What AST enables beyond grep
- [ ] **Definitively detect unassigned Task results** — check if `Task { }` or `Task(priority:) { }` is a standalone `ExpressionStmtSyntax` (fire-and-forget) vs assigned to a `let`/`var` via `PatternBindingSyntax`. Grep uses negative line matching which misses multi-line assignments
- [ ] **Check if fire-and-forget Task is inside a `deinit` or `viewDidDisappear`** — if the enclosing scope has teardown semantics, missing cancellation is a bug
- [ ] **Detect `.onAppear` containing `Task {`** — find `.onAppear` modifier where the closure body contains a `Task` initializer → should use `.task { }` modifier. AST can precisely match the modifier name + closure body, unlike grep multiline which is fragile
- [ ] **Detect `Task {}` in `init` or `body`** — SwiftUI View `init` or `body` containing Task creation → lifecycle mismatch (Task outlives view)
- [ ] **Detect `addTask` in TaskGroup without error handling** — `group.addTask { }` that can throw but isn't in a `try` context

## AST nodes to visit
- `FunctionCallExprSyntax` — detect `Task(...)`, `Task { }`, `.addTask`
- `PatternBindingSyntax` — check if Task result is captured
- `FunctionCallExprSyntax` with `.onAppear` — check trailing closure for Task creation
- `InitializerDeclSyntax`, `FunctionDeclSyntax` — enclosing scope analysis

## Confidence levels
- Unassigned Task in deinit/teardown → high
- `.onAppear` + `Task` → high (should be `.task`)
- Unassigned Task in general → medium (may be intentional fire-and-forget)
- Task in View.init/body → medium

## Summary of Changes
- FireAndForgetTaskCheck with scope-aware severity (high in deinit/viewDidDisappear)
- .onAppear+Task detection suggesting .task modifier
- Task in View body/init lifecycle mismatch detection
