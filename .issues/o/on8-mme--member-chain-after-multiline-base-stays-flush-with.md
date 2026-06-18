---
# on8-mme
title: Member chain after multiline base stays flush with statement keyword (return/let), not indented
status: completed
type: bug
priority: normal
created_at: 2026-06-18T16:29:49Z
updated_at: 2026-06-18T17:23:59Z
sync:
    github:
        issue_number: "734"
        synced_at: "2026-06-18T17:30:24Z"
---

## Report

User reports `.padding()`/`.background()` are 'incorrectly outdented' when chained after a multiline base inside a `#Preview`/`return`:

```swift
    return InTextCitationView(context: InTextCitationContext<PreviewCitation>(
        id: UUID(), within: UUID(), at: 0,
        style: TextAttachmentStyle(fontSize: 16, textColor: .black, backgroundColor: .white), ))
    .padding(30)          // <- user wants this indented (continuation)
    .background(...)
```

## Diagnosis

Reproduced minimally. The member-access chain that follows a *multiline* base expression de-indents to the **statement** indentation (flush with `return`/`let`), rather than indenting as a continuation.

Mechanism: `LayoutCoordinator.swift` ~line 395 `.contextual` case. When the prior breaking context spanned multiple lines, `contextualBreakingBehavior` becomes `.maintain`, so `isContinuationIfBreakFires = currentLineIsContinuation` (no added continuation indent). This is intentional swift-format behavior.

**This matches upstream swift-format exactly** (verified against ~/Developer/swiftiomatic-ref/swift-format on the same input — upstream also puts `.padding` flush with `return`). It is also covered by existing tests in `MemberAccessExprTests.swift` (the VStack/.padding(10) case), where the chain deliberately aligns flush with the multiline base.

## Decision needed

The requested output is a deliberate divergence from upstream + existing tests, not a clear regression. Awaiting user confirmation on whether to diverge.

## Confirmed policy (user)

Chain indent relative to its base, **only when the base spans multiple lines** (the `.maintain` path):
- Bare expression base → chain **+4** (was flush/+0). Changes `var body` SwiftUI pattern; rewrites MemberAccessExprTests VStack cases.
- return/throw/assignment-bound base → chain **+8**.
- **Single-line** base after return → stays **+4** (tmn-hqn unchanged; that golden fixture stays).

So: only the multiline-base contextual-break (`.maintain`) case changes — it should produce a continuation indent instead of maintaining the base column.

## Blast radius (measured)

Core change = flip the `.contextual` `.maintain` case in LayoutCoordinator from `currentLineIsContinuation` to `true` (chain indents +1 unit when base is multiline). Full suite: **3449 passed, 8 failed** — all 8 are statement-level chains matching the new policy:
- bare body/expr chains (VStack{}.padding, myWeirdFunc(){}.map{}, array.filter{}.map{}, VStack{}.overlay()) → now +4 ✓
- postfix-#if chains (3 IfConfigTests) → now indent +1 ✓
- assignment `let result = [...].filter{}` → flip gives +4, needs +8 (boost)

No nested/argument chains regressed. Implementation: flip (bare +4) + a scoped boost for binding operands (return/throw/assignment) to reach +8 when multiline, leaving single-line bindings at +4 (.continuation, unaffected).


## Summary of Changes

Implemented the confirmed policy: a member-access chain that continues a **multiline base** now indents as a continuation instead of aligning flush with the statement (upstream swift-format's behavior). Bare-expression chains get **+1** level; chains bound by `return`/`throw`/assignment get **+2**. Single-line bases are unchanged (tmn-hqn's `return entries.filter{}` stays +1).

### Mechanism
1. **Flip** (`LayoutCoordinator` `.contextual` → `.maintain` case): a chain break whose base spanned multiple lines now fires as a continuation (`isContinuationIfBreakFires = true`) rather than maintaining the base column. This gives the bare-expression `+1`.
2. **Boost** (the extra `+1` for bindings): new token trio `multilineChainBoostStart` / `multilineChainBoostDecision` / `multilineChainBoostEnd` brackets a binding operand whose value is a member-access chain (emitted in `arrangeKeywordOperandBreak`, `arrangeAssignmentBreaks`, and the `visitPatternBinding` `rhsHasInnerBreaks` path). The decision marker is placed right after the chain's **leftmost base** (via `chainLeftmostBaseLastToken`); at print time the marker compares the current line to the scope's start line, and iff the base wrapped, the next firing break pushes one **real** `ActiveOpenBreak` continuation-indent scope (removed at `…End`). Using a real open break keeps nested content (call arguments, closing delimiters) consistently indented.

### Why decide at the leftmost base
Deciding per-member would stair-step chains like `coder.decodeObject(…)?.intValue` (single-line base `coder` → must stay +1). Anchoring on the leftmost base and applying the decision uniformly avoids that, and the walk never descends into call/subscript arguments, so a chain nested inside an argument doesn't drive the outer decision.

### Tests
- New regression test `MemberAccessExprTests.multilineBaseChainIndentsAsContinuation` covering bare / return / assignment.
- Updated 7 existing expectations that asserted the old upstream flush behavior (3 `IfConfigTests` postfix-`#if`, 3 `MemberAccessExprTests`, 1 `FunctionCallTests`); renamed `postfixPoundIfNotIndentedIfClosingParenOnOwnLine` → `…Indented…` (now consistent with `postfixPoundIfBetweenOtherModifiers`).
- Full suite green: **3458 passed, 0 failed**.

### Note
This is a deliberate divergence from upstream swift-format (which keeps such chains flush). Postfix-`#if` modifier chains are also affected (a consequence of the flip), now consistent with the already-indented `#if`-after-modifier case.
