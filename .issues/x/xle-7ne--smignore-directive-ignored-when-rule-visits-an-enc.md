---
# xle-7ne
title: sm:ignore directive ignored when rule visits an enclosing node
status: completed
type: bug
priority: normal
created_at: 2026-05-02T02:47:50Z
updated_at: 2026-05-02T02:50:27Z
sync:
    github:
        issue_number: "624"
        synced_at: "2026-05-02T03:44:32Z"
---

## Problem

`// sm:ignore <Rule>` directives placed on or above a member declaration are silently ignored when the rule that emits the finding visits an *enclosing* node (e.g. `ClassDeclSyntax`) rather than the member itself.

Concrete repro: `UseWeakLetForUnreassigned` (`Sources/SwiftiomaticKit/Rules/Declarations/UseWeakLetForUnreassigned.swift`) walks `ClassDeclSyntax` / `ActorDeclSyntax` and inspects the member block. The pipeline gate `Context.shouldFormat` consults `RuleMask.ruleState` at the **visited node's start location** (the class start), which is *above* any in-body directive. Lone-line directive ranges are `[directive … EOF]`, so the class-start location is outside the range and the gate returns `.default` (rule runs). Finding is then emitted on the inner `var` token without any further mask check.

Net effect: for class-level rules, no placement of `// sm:ignore` suppresses per-member findings.

## Repro

```swift
final class PlatformTextView: NSTextView {
    var defaultFont: PlatformFont?

    // sm:ignore useWeakLetForUnreassigned
    weak var content: TextViewContent?   // still flagged
}
```

## Plan

- [x] Add failing test in `Tests/SwiftiomaticTests/Rules/UseWeakLetForUnreassignedTests.swift` covering both lone-line and trailing `// sm:ignore useWeakLetForUnreassigned` placements
- [x] In `Sources/SwiftiomaticKit/Syntax/SyntaxRule.swift`, consult `context.ruleMask.ruleState(ruleName, at: syntaxLocation)` inside `emitFinding` and skip emit when `.disabled`
- [x] Verify test passes; ran full suite (3192 passed)

## Summary of Changes

- `Sources/SwiftiomaticKit/Syntax/SyntaxRule.swift`: added a per-finding rule-mask gate in `emitFinding`. The pipeline gate at `Context.shouldFormat` checks `ruleMask.ruleState` at the *visited* node's start, but rules like `UseWeakLetForUnreassigned` that visit `ClassDeclSyntax`/`ActorDeclSyntax` and emit on inner members would bypass any per-member `// sm:ignore` directive. The new check resolves the rule key the same way `shouldFormat` does and consults the mask at the finding's anchor location, skipping emit when `.disabled`.
- `Tests/SwiftiomaticTests/Rules/UseWeakLetForUnreassignedTests.swift`: added `smIgnoreLoneLineSuppressesPerMember` and `smIgnoreTrailingSuppressesPerMember`.
