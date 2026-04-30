---
# kml-z1f
title: Cache shouldRewrite per visit in CompactStageOneRewriter
status: completed
type: task
priority: normal
created_at: 2026-04-30T00:45:06Z
updated_at: 2026-04-30T00:52:29Z
blocked_by:
    - uqb-m5z
sync:
    github:
        issue_number: "516"
        synced_at: "2026-04-30T00:55:14Z"
---

## Summary

Step 5 from `uqb-m5z`. `CompactStageOneRewriter.swift` calls `context.shouldRewrite(SomeRule.self, at: Syntax(node))` twice for every state-bearing rule (once before `willEnter`, once before `didExit`). With ~6 state-bearing rules on `ClassDeclSyntax` that's 12 `shouldRewrite` calls per class node, each doing a `RuleMask` location lookup + a `Configuration.isActive` map lookup.

## Plan

In each `override func visit(_:)` in `Sources/SwiftiomaticKit/Rewrites/CompactStageOneRewriter.swift`, extract a local for each rule with paired `willEnter`/`didExit` hooks:

```swift
let canRunNoForceTry = context.shouldRewrite(NoForceTry.self, at: Syntax(node))
if canRunNoForceTry { NoForceTry.willEnter(node, context: context) }
// ... super.visit + transforms ...
if canRunNoForceTry { NoForceTry.didExit(node, context: context) }
```

Mechanical edit; unaffected when there's only one gate (`willEnter`-only or single `transform`).

## Validation

- Tests stay green; behavior is unchanged.
- Performance: should show a small but measurable drop in the `testTwoStageCompactPipelineOnLayoutCoordinator` and `testFullFormatPipelinePerformance` tests (`SwiftiomaticPerformanceTests.RewriteCoordinatorPerformanceTests`).



## Summary of Changes

Cached `shouldRewrite` once per visit method in `Sources/SwiftiomaticKit/Rewrites/CompactStageOneRewriter.swift`. Each state-bearing rule is now hoisted into a local (`let runFoo = context.shouldRewrite(Foo.self, at: Syntax(node))`) at the top of the visit, and both the `willEnter` and `didExit` gates use that local.

### Visits updated

`AccessorBlockSyntax`, `AccessorDeclSyntax`, `ActorDeclSyntax`, `AsExprSyntax`, `AwaitExprSyntax` (kept the inner check on `concrete` since that node may have been mutated by `super.visit`; only the willEnter/didExit pair on `node` is cached), `ClassDeclSyntax` (12 → 6 calls), `ClosureExprSyntax` (10 → 5), `EnumDeclSyntax`, `ExtensionDeclSyntax`, `ForStmtSyntax`, `ForceUnwrapExprSyntax`, `FunctionCallExprSyntax`, `FunctionDeclSyntax` (10 → 5), `GuardStmtSyntax`, `IfExprSyntax`, `InitializerDeclSyntax`, `MemberAccessExprSyntax`, `RepeatStmtSyntax`, `StringLiteralExprSyntax`, `StructDeclSyntax`, `SubscriptCallExprSyntax`, `SubscriptDeclSyntax`, `VariableDeclSyntax`, `WhileStmtSyntax`.

### Validation

- `swift_package_test` clean: 3010 passed, 0 failed.
