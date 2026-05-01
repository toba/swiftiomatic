---
# 09z-px0
title: All-or-none wrap for || / && chains in if/guard/while conditions
status: draft
type: bug
priority: normal
created_at: 2026-05-01T21:02:04Z
updated_at: 2026-05-01T21:03:58Z
sync:
    github:
        issue_number: "611"
        synced_at: "2026-05-01T21:40:14Z"
---

## Context

When an if/guard/while condition has a chain of `||` (or `&&`) operands and doesn't fit on one line, the layout engine wraps inconsistently — some operands stay on the keyword line, others wrap. Desired behavior: all-or-none. If any operand wraps, every operand wraps onto its own line; otherwise the chain stays on one line.

### Before
```swift
if mergedFile != existing.file || mergedLine != existing.line
    || mergedDuration != existing.duration
{
```

### After
```swift
if mergedFile != existing.file
    || mergedLine != existing.line
    || mergedDuration != existing.duration
{
```

## Tasks

- [ ] Add failing PrettyPrint tests covering: chain fits → one line; chain overflows → each `||` on own line; nested `&&` inside `||` chain; `guard` and `while` variants
- [ ] Wrap the top of a logical-precedence chain in `.open(.consistent)` … `.close` in `visitInfixOperatorExpr` (`Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Operators.swift`)
- [ ] Add helper to detect "top of logical-operator chain" (parent is not same-precedence logical operator)
- [ ] Run filtered tests until green
- [ ] Run full suite to confirm no regressions
- [ ] Spot-check `sm format` on a real failing case

## Critical files

- `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Operators.swift` (change site)
- `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Appending.swift` (read-only reference for `stackedIndentationBehavior`)
- `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+ControlFlow.swift` (existing `.consistent` precedent)

Plan: `/Users/jason/.claude/plans/maybe-new-rule-unless-staged-shell.md`


## Update — needs design decision before implementation

Discovered that the current bin-packing behavior is **intentional, inherited from upstream apple/swift-format, and explicitly locked in by existing tests** in `Tests/SwiftiomaticTests/Layout/IfStmtTests.swift`:

- `conditionExpressionOperatorGrouping` (lines 432-461)
- `conditionExpressionOperatorGroupingMixedWithParentheses` (lines 464-495)
- mixed `&&`/`||` cases (lines 522-571)

Example of the existing locked-in behavior at linelength 50:

```swift
if someObj is SuperVerboselyNamedType
  || someObj is AnotherPrettyLongType
  || someObjc == "APlainString" || someObj == 4   // two operands share a line — by design
{
```

So this is not a small layout-engine fix. Treating it as one would:

1. Break 3-5 existing tests in `IfStmtTests` (and likely `GuardStmtTests` / `WhileStmtTests`).
2. Diverge visibly from upstream apple/swift-format — surprises anyone using `sm` as a `swift-format` drop-in via Xcode.
3. Require rewriting all the affected fixtures.

## Two paths

**A. Opt-in config (recommended).** New layout key, e.g. `logicalOperatorWrap: "stacked" | "binPacked"`, default `"binPacked"`. Existing tests stay green; new tests cover the stacked mode. Lower risk, reversible.

**B. New default + rewrite fixtures.** Aligns whole tool with the requested preference but diverges from upstream contract.

## Decision needed

Pick A or B before implementation. Set back to `ready` once decided.
