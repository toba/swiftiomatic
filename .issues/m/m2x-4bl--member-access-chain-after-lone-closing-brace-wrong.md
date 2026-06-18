---
# m2x-4bl
title: Member-access chain after lone closing brace wrongly indents as continuation
status: completed
type: bug
priority: normal
created_at: 2026-06-18T19:59:05Z
updated_at: 2026-06-18T20:26:04Z
sync:
    github:
        issue_number: "735"
        synced_at: "2026-06-18T20:26:47Z"
---

Regression from c3de9abb (on8-mme). A `.`-accessor chain following a closing brace that sits alone on its own line (e.g. a SwiftUI trailing-closure call like `Button {…} label: {…}` followed by `.labelStyle(…)`, or an `HStack { … }` followed by `.padding()`) is now indented one continuation level instead of staying flush with the closing brace.

Wrong:
```
            }
                .labelStyle(.iconOnly)
        }
            .padding()
```

Expected:
```
            }
            .labelStyle(.iconOnly)
        }
            .padding()  -> should be flush:
        }
        .padding()
```

The c3de9abb change flipped the contextual `.maintain` case in LayoutCoordinator from `currentLineIsContinuation` to always `true`, which was meant to indent chains continuing a *wrapped-argument* base (OuterView(args…) where args wrap on a content line) but over-applied to trailing-closure bases whose closing `}` sits alone on its own line at the base indent. Those should stay flush.

- [x] Add failing regression test for lone-closing-brace chain stays flush
- [x] Gate the .maintain indent so trailing-closure (lone closing delimiter) bases stay flush while wrapped-arg bases still indent
- [x] Reconcile the 7 expectations changed in c3de9abb (some encode the wrong behavior)
- [x] Full suite green


## Summary of Changes

Root cause: c3de9abb (on8-mme) flipped the contextual `.maintain` case in `LayoutCoordinator` from `currentLineIsContinuation` to an unconditional `true` so a `.`-chain continuing a *wrapped-argument* base (`OuterView(context: InnerContext(…))` → `.padding()`) would indent. That flip over-applied: it also indented chains continuing a base whose closing delimiter sits **alone on its own line** (a SwiftUI trailing-closure call `Button { … } label: { … }`, a block `HStack { … }`, an array literal, a `SomeFunction(\n…\n)` with the paren forced onto its own line, or a postfix-`#if`'s `#endif`), which should stay flush.

Fix (m2x-4bl): the `.maintain` indent and the on8-mme binding boost are now gated on a new `baseEndsAloneOnLine()` check — whether the base's last *rendered* line is just a closing delimiter (`)` / `]` / `}`) or `#endif`. This matches the user-visible rule exactly ("closing brace alone on a line followed by a `.`"):
- alone on its own line → chain stays flush (upstream behavior, via `currentLineIsContinuation`);
- closing delimiter inline after content (args wrapped, e.g. `…3))`) → chain still indents one continuation level (on8-mme preserved).

The decision is computed once per breaking-context scope (stored on `ActiveBreakingContext.baseEndedWithLoneClose`) so every element of a multi-part chain agrees — including a chain that continues past a postfix-`#if`, whose outer context resolves late.

Implementation details considered and rejected: a per-break "last fired break was a `.close`" flag (too local — only flushed the first chain element, and missed `#endif` which isn't a `.close`); broad propagation of that flag to all stacked contexts (captured the wrong observation from unrelated inner chains, e.g. inside a `VStack { … }` body). Output-line inspection at scope-resolution time is uniform across all cases.

Files:
- `Sources/SwiftiomaticKit/Layout/LayoutCoordinator.swift`: add `baseEndsAloneOnLine()`; gate `.maintain` and the multiline-chain boost on it; store `baseEndedWithLoneClose` on `ActiveBreakingContext`.
- Tests: add `MemberAccessExprTests.chainAfterLoneClosingBraceStaysFlush` (the reported HStack/Button case); revert the 7 expectations c3de9abb had changed to indent back to upstream flush across `MemberAccessExprTests`, `IfConfigTests` (incl. restoring `postfixPoundIfNotIndentedIfClosingParenOnOwnLine`), `FunctionCallTests`. `multilineBaseChainIndentsAsContinuation` (on8-mme wrapped-args) still passes — that behavior is intentionally preserved.

Full suite green: 3459 passed, 0 failed.
