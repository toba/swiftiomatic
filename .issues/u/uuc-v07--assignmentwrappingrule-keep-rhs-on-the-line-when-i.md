---
# uuc-v07
title: 'AssignmentWrappingRule: keep RHS on the = line when it fits'
status: completed
type: feature
priority: normal
created_at: 2026-04-11T22:58:59Z
updated_at: 2026-04-13T00:39:08Z
sync:
    github:
        issue_number: "201"
        synced_at: "2026-04-13T00:55:41Z"
---

## Problem

Chained expressions assigned to a variable sometimes format with an unnecessary line break after `=`, pushing the entire RHS to the next line with excessive indentation:

```swift
// bad
tempDir =
            FileManager.default.temporaryDirectory
            .appendingPathComponent("AddFolderToolTests-\(UUID().uuidString)")
            .path
```

The first segment of the chain fits on the `=` line. It should be:

```swift
// good
tempDir = FileManager.default.temporaryDirectory
    .appendingPathComponent("AddFolderToolTests-\(UUID().uuidString)")
    .path
```

Only wrap after `=` when placing the first segment on the same line would exceed the configured max line width.

## Scope

- **Scope:** `.format` (auto-correctable)
- **Category:** `Multiline/`
- **Rule ID:** `assignment_wrapping`

## Behavior

- Detect assignments (`let`, `var`, property assignments) where the RHS starts on a new line but the first token/segment of the RHS would fit on the `=` line within the max line width
- When correcting: move the first RHS segment up to the `=` line, re-indent continuation lines (chained `.` calls) by one indent level from the assignment target
- Leave alone when wrapping is genuinely needed (first segment would exceed line width)
- Should also apply to `return` expressions and default parameter values where the same pattern occurs

## Existing rules (not duplicated)

- `MultilineFunctionChainsRule` — enforces one-call-per-line in chains (SourceKit-based); does not address `=` wrapping
- `NoBlankLineInChainRule` — removes blank lines between chain segments; unrelated

## Tasks

- [x] Create `AssignmentWrappingRule` in `Sources/SwiftiomaticKit/Rules/Multiline/`
- [x] Add non-triggering and triggering examples
- [x] Run `swift run GeneratePipeline` to register
- [x] Add to example validation (automatic via `RuleExampleTests`)
- [x] Build and test


## Summary of Changes

Created `AssignmentWrappingRule` (format scope, correctable, enabled by default) with:
- `AssignmentWrappingRule.swift` — Visitor detects unnecessary wrapping; Rewriter moves RHS up and re-indents continuation lines
- `AssignmentWrappingOptions.swift` — `max_width` (default 120) and `indent_width` (default 4) via `FormatAwareRule`
- Handles both `let`/`var` declarations (`InitializerClauseSyntax`) and plain assignments (`InfixOperatorExprSyntax`)
- 4 triggering examples, 3 non-triggering examples, 4 correction pairs
- All tests pass
