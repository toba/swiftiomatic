---
# bbm-wcf
title: 'Postfix member-chain .member inside #if loses continuation indent when indentConditionalCompilationBlocks=false'
status: deferred
type: bug
priority: normal
created_at: 2026-06-27T16:11:31Z
updated_at: 2026-06-27T16:15:32Z
sync:
    github:
        issue_number: "742"
        synced_at: "2026-06-27T16:17:04Z"
---

Surfaced while porting swift-format #1225 (issue mid-kqi). Pre-existing, separate from the #endif merge fix.

## Repro
Config: respectsExistingLineBreaks=false, 2-space indent.

Input:
```
let x =
  base
  #if FLAG
  .foo()
  #endif
  .bar()
```

With indentConditionalCompilationBlocks=**false**, our output drops the member's continuation indent (`.foo()` at column 0):
```
let x = base
  #if FLAG
.foo()
  #endif
  .bar()
```

With indentConditionalCompilationBlocks=**true** our output is correct (matches upstream):
```
let x = base
  #if FLAG
    .foo()
  #endif
  .bar()
```

Upstream swift-format (#1225 test, default config = indentConditionalCompilationBlocks false) produces `.foo()` at 4 spaces.

## Expected
`.foo()` keeps its member-chain continuation indent regardless of indentConditionalCompilationBlocks. The flag should control the `#if`/`#endif` marker indent, not the chain member indent.

## Notes
- Postfix-if path: TokenStream+Breaks.swift insertContextualBreaks (~line 105-128) and the contextual member-break for calledMemberAccessExpr nested in postfix if (~line 143-150).
- Tasks:
  - [ ] Add failing test (indentConditionalCompilationBlocks=false)
  - [ ] Diagnose dropped continuation indent
  - [ ] Fix and verify

## Deferral Notes

**Upstream-parity behavior at a non-default setting — not a Swiftiomatic regression.**

Only manifests with `indentConditionalCompilationBlocks = false`. At the default (`true`, which forTesting and this project use) the output is correct and matches upstream's #1225 test exactly (`.foo()` at 4 spaces).

Root cause (token-stream diagnosis): `visitIfConfigClause` emits the `#if` content break as `.break(.same), .open` when indentCCB=false (no indent added). `#if FLAG` itself receives indent 2 from the member chain's contextual break that precedes it, but `.foo()` inside the `#if`'s `.open` group falls back to that group's anchor column (0), while `.bar()` (outside the `#if`) keeps the chain-continuation indent (2) — producing the `.foo()`(0) vs `.bar()`(2) inconsistency.

`visitIfConfigClause` is **verbatim-identical to upstream** for the non-switch case (the #1225 fix did not touch it; the postfix-if contextual breaks I ported match upstream). So upstream produces the same col-0 layout at indentCCB=false — this is shared-algorithm behavior, not our divergence.

### Why deferred (concerns to resolve before proceeding)
- Fixing requires diverging from upstream's verbatim `visitIfConfigClause` to inject a chain-continuation indent specifically for postfix-member-chain `#if` content at indentCCB=false. That risks regressing the many other `#if`-content cases this single code path governs (member blocks, code blocks, attribute lists).
- Low value: non-default setting; correct at default.
- Would need a careful audit of all `visitIfConfigClause` call contexts + a before/after run against upstream at indentCCB=false to confirm the target layout.

Recommend tackling only if a user hits it in practice, or as part of a broader indentCCB=false layout pass.
