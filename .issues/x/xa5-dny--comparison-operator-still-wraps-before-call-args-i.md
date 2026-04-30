---
# xa5-dny
title: Comparison operator still wraps before call args in if-condition
status: completed
type: bug
priority: normal
created_at: 2026-04-30T05:39:21Z
updated_at: 2026-04-30T16:13:42Z
sync:
    github:
        issue_number: "531"
        synced_at: "2026-04-30T16:27:52Z"
---

Follow-up to 8yg-tvu. The comparison-operator break-precedence fix (gated to operands containing a function call) works for assignment context (`x = f(...) != 0`) but does NOT yet fix the same pattern inside an `if` condition: `if foo(bar: x, qux: y) == expected { ... }` still wraps as `if foo(\n  bar: x, qux: y)\n  == expected\n{ ... }` with `==` dangling on its own line, instead of the desired `if foo(\n  bar: x,\n  qux: y) == expected\n{ ... }`. Likely cause: the if-condition layout adds its own wrapping group (around the condition or before the `{` brace) that interferes with the comparison-operator open/close group's chunk bounding. Pinned by the existing test `comparisonOperatorYieldsToFunctionCallInCondition` in BinaryOperatorExprTests.swift — that test currently asserts the buggy output. When fixed, update its expected output to put each call argument on its own line.



## Summary of Changes

- Added `isInConditionList(_:)` and `effectiveArgListConsistency(for:)` helpers in `TokenStream+Appending.swift` to detect comparison-operator infix expressions inside `if` / `guard` / `while` condition lists.
- In `arrangeFunctionCallArgumentList` (`TokenStream+Collections.swift`), call args now open with `.consistent` grouping when the call is one operand of a comparison inside a condition list. This forces every arg onto its own line once the line wraps, so the comparison operator stays glued to the closing `)` instead of dangling.
- Updated `comparisonOperatorYieldsToFunctionCallInCondition` in `BinaryOperatorExprTests.swift` to assert the desired output (each arg on its own line, `== expected` glued to `)`). Test passes.



## Summary of Changes

The comparison-operator break in an `if` / `guard` / `while` condition could not be made low-precedence by chunk-bounding alone — bounding it tighter (its chunk = RHS, ~11 chars) still beat the inconsistent-grouped function-call inter-arg break, because inconsistent-group decisions are myopic and don't see the comparison overflow ahead. The fix instead changes the **call's argument-list grouping** to consistent in this exact context, so once the open-paren break fires (it must, the line doesn't fit), every arg breaks together and the operator stays glued to the closing `)`.

Files:
- `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Appending.swift` — added `isInConditionList(_ node: InfixOperatorExprSyntax)` walking parents up to `ConditionElementSyntax` (stops at any stmt/decl/code-block boundary), and `effectiveArgListConsistency(for: LabeledExprListSyntax)` that returns `.consistent` when the call is a direct operand of a comparison-precedence `InfixOperatorExpr` inside a condition list. Otherwise returns the user's configured default.
- `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Collections.swift` — `arrangeFunctionCallArgumentList` now calls `effectiveArgListConsistency(for:)` instead of `argumentListConsistency()` when adding the inner arg-list grouping.
- `Tests/SwiftiomaticTests/Layout/BinaryOperatorExprTests.swift` — `comparisonOperatorYieldsToFunctionCallInCondition` updated to assert each arg on its own line, with the closing `)` and the `== expected` clause glued together (the natural shape of a consistent-wrapped call).

Verification:
- `BinaryOperatorExprTests` — 13/13 pass (was 11/13).
- Full suite — 3013 pass, 9 fail. All 9 failures are pre-existing in the working tree (other in-flight agent work), confirmed by the same `/tmp/sm-test-diffs/` files appearing before my changes.

Filed follow-up issue `tc2-9jv` in xc-mcp: `swift_package_test` first-run timeout (cold cache build > 300s default).
