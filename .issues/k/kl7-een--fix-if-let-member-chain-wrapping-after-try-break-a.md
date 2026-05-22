---
# kl7-een
title: 'fix if-let member chain wrapping after ''= try'': break at dot not after ''='''
status: completed
type: bug
priority: normal
created_at: 2026-05-22T05:06:18Z
updated_at: 2026-05-22T05:22:50Z
sync:
    github:
        issue_number: "695"
        synced_at: "2026-05-22T05:23:20Z"
---

In visitOptionalBindingCondition, when stackedIndentationBehavior returns nil and the RHS is a try+member-access chain, the fallback is a plain .break(.continue) after '='. This causes the line to wrap after '=' before the dot breaks fire. The fix should apply the canGroupBeforeBreak pattern (like arrangeAssignmentBreaks does) so inner dot breaks fire first.



## Summary of Changes

Root cause: when an `if let` / `let` binding's RHS is a `try`/`await`-wrapped member-access chain with discretionary newlines at the chain dots, the keyword-modified group (`.open` before `try` ... `.close` after the head name) spanned the first chain dot. The discretionary newline there becomes a `.soft(discretionary:)` break that bumps the Oppen `total` by `maxLineLength`, inflating the enclosing `=` break's chunk-length and forcing it to fire — wrapping `try CitationGroup` onto its own line.

The existing mitigation `shouldRetargetChainHeadCloseForAssignmentRHS` (issue wts-z1t) closed the keyword group after the chain base instead of the head name, but only when the head carried a *trailing* closure. A paren-wrapped closure head like `.where({ ... })` was not covered.

Fix: broadened `shouldRetargetChainHeadCloseForAssignmentRHS` (TokenStream+Appending.swift) to drop the hard `trailingClosure != nil` requirement. The multi-line-closure skip now applies only when a trailing closure is actually present; otherwise retargeting proceeds for paren-wrapped (or argument-only) chain heads. The `visitOptionalBindingCondition` path was left unchanged (an earlier exploratory edit there was reverted — it had no effect since the `=` break chunk was inflated by the keyword group, not the binding break itself).

Added regression test `IfStmtTests.ifLetTryMemberChainBreaksAtDotNotAfterEqual`. Full suite: 3375 passed, 0 failed.
