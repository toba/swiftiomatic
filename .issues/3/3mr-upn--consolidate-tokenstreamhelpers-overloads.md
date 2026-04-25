---
# 3mr-upn
title: Consolidate TokenStream+Helpers overloads
status: completed
type: task
priority: low
created_at: 2026-04-25T20:42:40Z
updated_at: 2026-04-25T22:08:54Z
parent: 0ra-lks
sync:
    github:
        issue_number: "435"
        synced_at: "2026-04-25T22:35:12Z"
---

Several `TokenStream+Helpers` functions have multiple near-identical overloads.

## Findings

- [x] `areBracesCompletelyEmpty` collapsed from 3 overloads → 1 (Element constraint was unused in the body)
- [x] `arrange*ParameterClause` overloads now share a private `arrangeParenthesizedParameters(leftParen:rightParen:isEmpty:forcesBreakBeforeRightParen:)` helper
- [x] `arrangeBracesAndContents`: left as-is. Attempted to merge the `Element == Syntax` and `Element == DeclSyntax` byte-identical overloads into one unconstrained generic, but it broke 4 layout tests (CommentTests/IfStmt, FunctionDecl, ForInStmt, IgnoreNode) — the constraints participate in overload resolution against the `Element: SyntaxProtocol` overload (which has different `before`/`arrangeNonEmptyBraces` behavior). Reverted to preserve correctness.

## Test plan
- [x] All 2795 tests pass; format output unchanged


## Summary of Changes

- Consolidated `areBracesCompletelyEmpty` from 3 overloads → 1 (the Element constraint was unused in the body).
- Extracted `arrangeParenthesizedParameters` private helper that the three `arrange*ParameterClause` overloads now delegate to.
- Investigated `arrangeBracesAndContents` consolidation — the `Element` constraints encode subtle overload-resolution behavior (the `: SyntaxProtocol` overload uses `ignoresDiscretionary: true` and `openBraceNewlineBehavior`), so the four overloads must remain. Documented this in the issue.
- All 2795 tests pass.
