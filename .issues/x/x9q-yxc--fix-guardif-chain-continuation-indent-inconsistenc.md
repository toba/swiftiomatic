---
# x9q-yxc
title: Fix guard/if chain continuation indent inconsistency with AlignWrappedConditions
status: completed
type: bug
priority: normal
created_at: 2026-05-24T19:18:35Z
updated_at: 2026-05-24T19:30:27Z
sync:
    github:
        issue_number: "705"
        synced_at: "2026-05-24T19:32:19Z"
---

With AlignWrappedConditions=true and BreakBeforeGuardConditions=false, a member-access chain as the first guard/if condition wraps its sub-lines at continuation indent (+4) while subsequent conditions use alignment indent (+6). Fix: fall back to .continuation for subsequent conditions when the first condition contains a member-access chain, so all wrapped lines use the same indent.\n\n- [x] Add failing test\n- [x] Fix guardBreakKind in visitGuardStmt\n- [x] Fix ifBreakKind in visitIfExpr\n- [x] Fix whileBreakKind in visitWhileStmt

## Summary of Changes

Added `isMultiStepCallChain` helper to detect multi-step chains with function calls (e.g. `obj.first().second()`). Updated `conditionContainsMemberChain` to use it. When the first guard/if/while condition is such a chain, `guardBreakKind`/`ifBreakKind`/`whileBreakKind` falls back to `.continuation` instead of `.alignment`, so all wrapped lines use the same indent. Added 3 tests in `AlignWrappedConditionsTests`.
