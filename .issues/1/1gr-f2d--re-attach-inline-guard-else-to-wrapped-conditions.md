---
# 1gr-f2d
title: Re-attach inline guard else to wrapped conditions when it fits
status: completed
type: bug
priority: normal
created_at: 2026-06-17T01:05:10Z
updated_at: 2026-06-17T01:12:32Z
sync:
    github:
        issue_number: "731"
        synced_at: "2026-06-17T01:35:35Z"
---

Reverse the guard-else behavior introduced in f4ec13c2 ('always break before guard else when conditions wrap'). The user wants an inline single-statement `else { stmt }` to stay glued to the closing condition line when it fits, rather than always dropping `else` to its own line when conditions wrap.

Example desired:
guard let view = notification.object as? EmbeddedTextView,
      let cellID = view.cellID else { return }

instead of the current:
guard let view = notification.object as? EmbeddedTextView,
      let cellID = view.cellID
else { return }

## Plan
- [x] Hybrid attach logic in BreakBeforeGuardConditions.swift (glue whole else { stmt } when it fits, else drop as a unit)
- [x] Restored attachesInlineElse* / threeConditionsGlueElseWhenInlineBodyFits assertions
- [x] Full suite green: 3456 passed, 0 failed

## Summary of Changes

Reversed f4ec13c2's 'always break before guard else when conditions wrap' — but as a **hybrid** rather than a blind revert, which keeps the WebSocket fix that motivated the original change.

`BreakBeforeGuardConditions.visitGuardStmt`: when conditions wrap (count > 1) and the body is a single-statement single-line `else { stmt }`, open the else group BEFORE the break so the break measures the entire `else { stmt }` unit:
- fits on the closing condition line → glued (user's request)
- doesn't fit → whole `else { stmt }` drops to its own line at base indent (no more 'else { glued + body wrapped' intermediate)

Multi-statement / source-multiline bodies still break else as before. In `inline` mode, `LayoutSingleLineBodies` collapses bodies first, so this also covers originally-wrapped bodies.

Tests: `attachesInlineElseToWrappedConditions`, `attachesInlineElseUnderAlignedConditions`, `threeConditionsGlueElseWhenInlineBodyFits` restored to glue expectations. The not-fitting tests (`breaksElseWithInlineBodyWhenConditionsWrap`, `breaksElseUnderAlignedConditionsToBaseIndent`, `breaksElseInDeeplyNestedAlignedConditions`, `multiStatementBodyAlwaysBreaksElse`) keep dropping else — unchanged.
