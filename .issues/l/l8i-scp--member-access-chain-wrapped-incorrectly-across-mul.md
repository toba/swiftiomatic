---
# l8i-scp
title: Member access chain wrapped incorrectly across multiple lines
status: completed
type: bug
priority: normal
created_at: 2026-04-26T18:42:10Z
updated_at: 2026-04-27T18:02:28Z
sync:
    github:
        issue_number: "454"
        synced_at: "2026-04-27T18:34:22Z"
---

## Problem

The formatter wraps a member access chain across multiple lines incorrectly, splitting each segment onto its own line and over-indenting:

```swift
queryOutput
    .debug_recordChangeTag =
    coder
    .decodeObject(of: NSNumber.self, forKey: "_recordChangeTag")?
    .intValue
```

## Expected

The chain should keep the base receiver attached and only wrap at the natural continuation points:

```swift
queryOutput.debug_recordChangeTag = coder
    .decodeObject(of: NSNumber.self, forKey: "_recordChangeTag")?.intValue
```

## Tasks

- [x] Add a failing test reproducing the wrap
- [x] Identify the layout/wrap rule responsible
- [x] Fix wrapping so simple receiver.member assignments stay on one line
- [x] Verify with full test suite
- [ ] Update existing `assignmentWithMemberAccessLHSAndChainRHS` to expected user layout (chain break wins over args break)
- [ ] Add second test at shorter line length asserting break before `.intValue`
- [ ] Fix `visitFunctionCallExpr` so the `.open/.close` around `base.decodeObject` does not suppress the chain break when the call is part of an outer member-access chain on an assignment RHS
- [ ] Re-run full Layout test suite



## Summary of Changes

Two coordinated edits in `Sources/SwiftiomaticKit/Layout/Tokens/`:

1. **`TokenStream+Operators.swift` `visitInfixOperatorExpr`** — wrap the LHS of an assignment in `.open/.close` when the LHS is a member-access chain. This bounds the LHS contextual break's chunk to the LHS group rather than letting it span the entire RHS, so the LHS no longer splits across lines.

2. **`TokenStream+Appending.swift` `maybeGroupAroundSubexpression`** — extend the existing assignment-RHS exemption (already in place for `FunctionCallExpr`) to cover `MemberAccessExpr` and `SubscriptCallExpr`. Without this, the surrounding `.open/.close` made the `=` break see the entire RHS as one chunk, forcing it to fire prematurely instead of letting the chain absorb the wrap.

New test: `Tests/SwiftiomaticTests/Layout/AssignmentExprTests.swift::assignmentWithMemberAccessLHSAndChainRHS`. All 24 Layout tests + 2966 Swiftiomatic tests pass (2 unrelated `GeneratedFilesValidityTests` failures from other agents' in-flight work).

## Review needed

User to verify the resulting wrap matches expectations: the formatter now keeps `queryOutput.debug_recordChangeTag = coder.decodeObject(` together on line 1 and breaks inside the args. The originally-requested layout (break before `.decodeObject`) would require a forward-looking heuristic — separate concern.



## Reopened

User review: the fix landed but the resulting wrap still violates documented break precedence. The chain break (`.decodeObject`, rank 2) must fire before the function-call args break (rank 3) and before the `=` break (rank 4).

Current (wrong):
```
queryOutput.debug_recordChangeTag = coder.decodeObject(
    of: NSNumber.self, forKey: "_recordChangeTag")?.intValue
```

Wanted:
```
queryOutput.debug_recordChangeTag = coder
    .decodeObject(of: NSNumber.self, forKey: "_recordChangeTag")?.intValue
```

At shorter line lengths, should also break before `.intValue`.



## Resume Fix

Replaced the inner `.open/.close` group around `base.method` in `visitFunctionCallExpr` with a chain-extending group around `.method(args)` when the call is a step in an outer member-access chain (no trailing closure). This makes the contextual chain break before `.method` (rank 2) win over the function-call args break (rank 3) and the `=`/`guard` break (rank 4), matching the documented precedence.

Files:
- `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Appending.swift` — added `isPartOfOuterMemberAccessChain` helper.
- `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Collections.swift::visitFunctionCallExpr` — switch grouping when call is mid-chain.
- `Tests/SwiftiomaticTests/Layout/AssignmentExprTests.swift` — updated `assignmentWithMemberAccessLHSAndChainRHS` to wanted output; added `assignmentWithMemberAccessLHSAndChainRHSShortLine` for the cascading wrap.
- `Tests/SwiftiomaticTests/Layout/AssignmentExprTests.swift::assignmentWithSimpleMemberAccessChain` — updated expected to honor chain-first precedence.
- `Tests/SwiftiomaticTests/Layout/GuardStmtTests.swift::guardWithFuncCall` — updated expected to honor chain-first precedence.

All 2978 Swiftiomatic tests pass.
