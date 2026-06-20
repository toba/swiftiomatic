---
# gl8-vhc
title: Assignment RHS member chain with ?? wraps after = instead of keeping base on the = line
status: completed
type: bug
priority: normal
created_at: 2026-06-20T02:21:17Z
updated_at: 2026-06-20T02:48:32Z
sync:
    github:
        issue_number: "737"
        synced_at: "2026-06-20T02:49:53Z"
---

## Problem

A member-access chain on the RHS of an assignment, when the whole RHS is a binary op (e.g. `chain.max() ?? 1`), wrongly breaks right after `=`, pushing the base onto its own line.

Wrong:
```
let columns =
    children
    .filter { $0.type == .tableRow }
    .map(\.children.count)
    .max() ?? 1
```

Desired:
```
let columns = children
    .filter { $0.type == .tableRow }
    .map(\.children.count)
    .max() ?? 1
```

The base (`children`) should stay on the `=` line and the chain dots wrap.

## Cause hypothesis

Outermost RHS node is an `InfixOperatorExpr` (`??`), so `isMemberAccessChain(rhs)` is false; arrangeAssignmentBreaks enters the group-before-break branch via `isCompound`. The `=` break's chunk over-extends.

## Tasks
- [x] Reproduce with a layout test + dump token stream
- [x] Identify precedence bug
- [x] Fix and verify no regressions


## Summary of Changes

**Root cause.** The bug only manifests when the chain is *already wrapped* (a discretionary newline at each dot). `shouldRetargetChainHeadCloseForAssignmentRHS` (TokenStream+Appending.swift) walks up from the chain head to find the enclosing assignment so it can close the head's `.open` group after the chain *base* (`children`) rather than after `base.<name>` (`children.filter`) — keeping the soft break at the first dot from inflating the enclosing `=` break's chunk. The walk only continued through *assignment* operators, so for `chain.max() ?? 1` it stopped at the `??` `InfixOperatorExpr` and returned false. The head group then closed after `children.filter`, the `=` break's chunk spanned the whole chain (token-stream Length 116 vs 4 for a pure chain), and the forced inner breaks dragged the `=` break along — producing a spurious newline after `=`.

**Fix.** In the walk's `default` case, when the chain is the *left* operand of a non-assignment `InfixOperatorExpr`, treat the operator as transparent and keep walking up. If the binary expression is itself the assignment/binding RHS, retargeting now applies and the head group closes after `base`. Only the left operand is followed (a chain on the right of the operator isn't adjacent to `=`).

**Files**
- `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Appending.swift` — extend `shouldRetargetChainHeadCloseForAssignmentRHS`.
- `Tests/SwiftiomaticTests/Layout/MemberAccessExprTests.swift` — regression test `assignmentChainWithNilCoalescingKeepsBaseOnEqualLine`.

Full suite green (3462 passed). Verified end-to-end with the freshly built `sm` on the real `thesis/Testing/TestFixtures/MockNode.swift` snippet (lineLength 100): `let columns = children` stays on the `=` line.
