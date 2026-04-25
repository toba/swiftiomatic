---
# qlx-se1
title: Investigate redundant wrap rules
status: completed
type: task
priority: normal
created_at: 2026-04-25T00:14:55Z
updated_at: 2026-04-25T00:17:40Z
parent: os4-95x
sync:
    github:
        issue_number: "391"
        synced_at: "2026-04-25T01:59:57Z"
---

Determine whether WrapMultilineStatementBraces and WrapMultilineFunctionChains are redundant with existing pretty-printer behavior.

- [x] WrapMultilineStatementBraces: **NOT redundant** — guard statements have NO reset break (total gap); reset fires on continuation state only, not indentation comparison
- [x] WrapMultilineFunctionChains: **NOT redundant** — complementary: rewrite enforces consistent dot placement, layout setting controls indentation behavior; neither replaces the other
- [x] Both rules provide non-redundant value and should stay as rewrite rules


## Summary

Neither wrap rule is redundant with the pretty-printer.

**WrapMultilineStatementBraces**: Guard statements have no token stream visitor at all — total coverage gap. For other nodes, the rewrite rule checks AST indentation levels while the reset break uses printer continuation state — different logic that can disagree.

**WrapMultilineFunctionChains**: Complementary, not redundant. The rewrite rule enforces consistent dot-per-line placement in chains. The layout setting controls indentation consistency for nested chains. Different phases, different purposes.
