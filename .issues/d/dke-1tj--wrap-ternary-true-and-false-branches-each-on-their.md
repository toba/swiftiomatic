---
# dke-1tj
title: 'Wrap ternary: true and false branches each on their own line'
status: completed
type: feature
priority: normal
created_at: 2026-04-25T19:59:18Z
updated_at: 2026-04-25T21:22:09Z
sync:
    github:
        issue_number: "415"
        synced_at: "2026-04-25T22:35:07Z"
---

When a ternary expression has to wrap at all, the `?` (true) and `:` (false) portions should each be on their own line. Currently the formatter may keep the true branch on the same line as the condition while wrapping only the false branch.

## Example

Currently produces:

```swift
pendingLeadingTrivia = trailingNonSpace.isEmpty
    ? token.leadingTrivia : token.leadingTrivia + trailingNonSpace
```

Should produce:

```swift
pendingLeadingTrivia = trailingNonSpace.isEmpty
    ? token.leadingTrivia
    : token.leadingTrivia + trailingNonSpace
```

(Indentation in the example is illustrative — the rule is about line-breaking the two branches, not the specific indent.)

## Behavior

- If the ternary fits on one line, leave it alone.
- If wrapping is needed at all, break before `?` AND before `:`, putting the true branch and false branch on separate lines.

## Tasks

- [x] Locate the rule/layout pass responsible for ternary wrapping
- [x] Add a failing test reproducing the current single-line-true-branch behavior
- [x] Implement: ternary wrapping moved to a syntax rewriter (`WrapTernary`) that inserts discretionary newlines before both `?` and `:` when the expression overflows `LineLength`
- [x] Verify existing ternary tests still pass (full suite: 2795 passed, 0 failed)
- [x] Nested ternary handling — nested ternaries only wrap on intrinsic length to avoid double-wrapping when the parent already wraps



## Summary of Changes

**Approach: separate concerns.** The pretty printer no longer makes ternary wrap decisions; a new `WrapTernary` `RewriteSyntaxRule` decides, and the printer just respects discretionary newlines via `RespectsExistingLineBreaks`.

### Files

- `Sources/SwiftiomaticKit/Rules/Wrap/WrapTernary.swift` (new) — for each `TernaryExprSyntax`, computes a single-line normalized length. If the ternary already has a newline before `?` or `:`, normalizes the other to match. Otherwise wraps when `(startCol - 1) + length > LineLength`. Nested ternaries (those inside another `TernaryExprSyntax`) only wrap when their intrinsic length alone exceeds `LineLength` — using their raw source column would over-wrap once the parent ternary wraps and shifts them.
- `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+TypesAndPatterns.swift` — `visitTernaryExpr` now emits only `.break(.open(kind: .continuation)) ... .break(.close)` pairs around `?` and `:` (no `.open(.inconsistent)` group tokens). Wrap decisions are deferred to the rewriter; the break-open/close pairs preserve continuation-indent context for wrapped sub-expressions inside each branch.
- `Tests/SwiftiomaticTests/Layout/LayoutTestCase.swift` — `prettyPrintedSource` now applies `WrapTernary` before pretty printing so layout tests see the same input the production pipeline produces. (Other rules are intentionally not run, to keep layout tests focused on PP behavior.)
- `Tests/SwiftiomaticTests/Layout/TernaryExprTests.swift` — added `bothBranchesOnTheirOwnLineWhenTernaryWraps`; updated `ternaryExprs` expected output to break each branch onto its own line.
- `Tests/SwiftiomaticTests/Layout/IfConfigTests.swift` — `postfixPoundIfAfterClosingBrace` expected output updated for the new wrapping behavior.
- `Sources/SwiftiomaticKit/Generated/{Pipelines,ConfigurationRegistry}+Generated.swift` — regenerated via `swift run Generator` to register the new rule.

### Idempotency

After the first format pass, the source has a newline before both `?` and `:`. On the second pass, the rule sees both newlines and is a no-op. PP respects them and produces identical output. ✓

### Verification

- All 8 `TernaryExprTests` pass.
- Full test suite: 2795 passed, 0 failed.
- Manual CLI check on the original example from `LeadingDotOperators.swift` produces the desired three-line wrap.
