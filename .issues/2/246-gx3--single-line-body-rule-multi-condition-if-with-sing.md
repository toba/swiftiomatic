---
# 246-gx3
title: 'single line body rule: multi-condition if with single-statement body should collapse'
status: completed
type: bug
priority: normal
created_at: 2026-05-01T02:24:08Z
updated_at: 2026-05-01T03:14:22Z
sync:
    github:
        issue_number: "599"
        synced_at: "2026-05-01T03:50:33Z"
---

When the single-line-body rule is active, a multi-condition `if` with a single-statement body should collapse the body onto the same line as the closing condition (like `guard` does today).

## Repro

Input:
```swift
        if let existing = try? String(contentsOf: url, encoding: .utf8),
           existing == content
        {
            return
        }
```

## Expected

```swift
        if let existing = try? String(contentsOf: url, encoding: .utf8),
           existing == content { return }
```

The body is a single statement (`return`), so it should collapse to `{ return }` on the same line as `existing == content` — matching how `guard` is handled.

## Actual

The body remains expanded across multiple lines and the opening brace stays on its own line.

## Notes

- Spotted in `Sources/SwiftiomaticKit/Configuration/Configuration+UpdateText.swift` (currently modified in the working tree).
- Likely needs the single-line-body rule to recognize multi-line condition lists with the brace on its own line and still apply the collapse.



## Summary of Changes

The `WrapSingleLineBodies.inlineIf` stage-1 rewrite was already collapsing the body to `{ stmt }` correctly — the bug was that the pretty printer was *re-wrapping* it. Two compounding issues in the layout token stream:

1. `CodeBlockItemSyntax` wrapped every if-statement in a `.consistent` group spanning conditions + body. When conditions wrapped, this group force-broke the body's `.break(.open(.block))`, dropping `{ return }` content onto its own lines.
2. In `visitIfExpr`, the consistent conditions group's `.close` was declared BEFORE the per-condition close breaks, so afterMap reversal emitted the close AFTER the per-condition close break. That break inherited the consistent group's force-break flag and emitted a newline before `{`.

### Fix

- `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+MembersAndBlocks.swift`: skip the if-stmt consistent wrapper when the if has no `else` and the body is already a single-line single-statement in source.
- `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+ControlFlow.swift::visitIfExpr`: when attaching an inline body, declare the consistent group's `.close` AFTER the per-condition close breaks so it emits FIRST (popping the force-break flag). Replace the default `.break(.reset)` with `.printerControl(.clearContinuation), .break(.same, size: 1, .elective(ignoresDiscretionary: true))` so the brace stays glued to the closing condition. Mirrors the trick already used in `BeforeGuardConditions` for `else { stmt }`.

### Tests

- `Tests/SwiftiomaticTests/Rules/Wrap/SingleLineBodiesTests.swift::multiLineConditionWithTryAndBraceOnOwnLineInlines` — covers the stage-1 rewrite for the user's exact input.
- `Tests/SwiftiomaticTests/Layout/IfStmtTests.swift::attachesInlineBodyToWrappedConditions` — covers the full pretty-print pipeline.
- Updated three existing tests whose expectations encoded the old (Apple-style) behavior of dropping `{` onto its own line when conditions wrap with a single-statement body: `IfStmtTests.optionalBindingConditions`, `IfStmtTests.multipleIfStmts`, `BinaryOperatorExprTests.comparisonOperatorYieldsToFunctionCallInCondition`.

Filtered run of `IfStmtTests|GuardStmtTests|SingleLineBodiesTests|WhileStmtTests|AlignWrappedConditionsTests|BinaryOperatorExprTests` is green (142 tests). Full-suite failures are unrelated WIP in other agents' modified files (`EnsureLineBreakAtEOF.swift`, `BeforeEachArgument.swift`, etc.).
