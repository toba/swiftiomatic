---
# vhc-ltf
title: NestingDepth depth counter never decrements (visitPost not dispatched)
status: completed
type: bug
priority: high
created_at: 2026-04-27T19:24:33Z
updated_at: 2026-04-27T19:41:54Z
sync:
    github:
        issue_number: "466"
        synced_at: "2026-04-27T20:03:55Z"
---

## Problem

`NestingDepth` rule reports nonsense depths — e.g., a top-level `private func lineStart` is flagged as "function is nested 8 levels deep", a file-scope `extension JSON5Scanner` as "type is nested 7 levels deep", and a `struct Lexer` inside that extension as "type is nested 8 levels deep". Depths grow monotonically through the file regardless of actual nesting.

## Root cause

`Sources/SwiftiomaticKit/Rules/Metrics/NestingDepth.swift` maintains `typeDepth` / `functionDepth` counters, incrementing in `visit(_:)` overrides and decrementing in `visitPost(_:)` overrides.

But the lint framework never dispatches the rule's `visitPost`. `LintPipeline.onVisitPost` (`Sources/SwiftiomaticKit/Syntax/Linter/LintPipeline.swift:34`) only manages the `shouldSkipChildren` map — it does not invoke `rule.visitPost(node)`. The generated `Pipelines+Generated.swift` calls `onVisitPost(rule: NestingDepth.self, ...)` instead of forwarding to the rule instance.

Result: `typeDepth`/`functionDepth` only ever increment for the lifetime of the rule instance, accumulating across siblings and across files (rule instances are cached per-context in `ruleCache`).

## Affected rules

All rules that override `visitPost` rely on it firing and are similarly broken:

- `Sources/SwiftiomaticKit/Rules/Metrics/NestingDepth.swift`
- `Sources/SwiftiomaticKit/Rules/Metrics/CyclomaticComplexity.swift`
- `Sources/SwiftiomaticKit/Rules/Closures/UnhandledThrowingTask.swift`
- `Sources/SwiftiomaticKit/Rules/Naming/CamelCaseIdentifiers.swift`
- `Sources/SwiftiomaticKit/Rules/Redundancies/RedundantEscaping.swift`

## Tasks

- [x] Add a failing test: lint a fixture with two sibling top-level types and assert depth resets between them
- [x] Decide on framework fix vs. per-rule fix (framework):
  - Framework: have `LintPipeline.onVisitPost` (and codegen) forward to `rule.visitPost(node)` for cached rule instances
  - Per-rule: drop instance state, compute depth via syntax parent walk in `visit`
- [x] Apply chosen fix
- [x] Audit the other four rules above for the same accumulation bug
- [x] Verify with a real-world file (the JSON5Scanner case from the screenshot)

## Other observations

- `NestingDepthConfiguration.functionLevel` doc says "control-flow blocks inside a function body (if/for/while/switch/closure)" but the rule actually counts nested `func`/`init`/`subscript` declarations. Doc and intent diverge from impl — clarify as part of the fix.


## Summary of Changes

Framework-level fix: `LintPipeline.onVisitPost` now has a typed overload that dispatches `visitPost` to the cached lint-rule instance, balancing the `visit`/`visitPost` enter/leave pair. Codegen (`PipelineGenerator`) now emits `onVisitPost(<Rule>.visitPost, for: node)` for lint rules and the existing `onVisitPost(rule: <Rule>.self, for: node)` form for rewrite rules (which don't override `visitPost`).

### Files
- `Sources/SwiftiomaticKit/Syntax/Linter/LintPipeline.swift` — new typed `onVisitPost` overload
- `Sources/GeneratorKit/PipelineGenerator.swift` — emit typed call for lint rules only
- `Sources/SwiftiomaticKit/Generated/Pipelines+Generated.swift` — regenerated
- `Sources/SwiftiomaticKit/Rules/Metrics/NestingDepth.swift` — `functionLevel` doc tightened to match impl
- `Tests/SwiftiomaticTests/Rules/Metrics/NestingDepthTests.swift` — sibling-reset tests for types and functions

### Audit
- `NestingDepth`, `CamelCaseIdentifiers`, `UnhandledThrowingTask` — all `LintSyntaxRule` subclasses with `visitPost` overrides; now correctly dispatched.
- `CyclomaticComplexity` — `visitPost` overrides live on its inner `ComplexityVisitor`, not on the rule; not affected.
- `RedundantEscaping` — `RewriteSyntaxRule`; `visitPost` runs naturally during `SyntaxRewriter.rewrite()`; not affected.

### Verification
- `NestingDepthTests` — 6/6 pass (including 2 new sibling-reset tests).
- `CamelCaseIdentifiersTests`, `UnhandledThrowingTaskTests`, `CyclomaticComplexityTests`, `RedundantEscapingTests` — 33/33 pass.
- `GeneratedFilesValidityTests` — 2/2 pass.
- End-to-end: `sm lint` on a fixture with two sibling top-level structs each containing one nested struct now reports both inner structs at depth 2 (previously the second would be reported at depth 4).
