---
# 7fp-ghy
title: 'ddi-wtv-9: convert deferred rules; complete the rule port'
status: completed
type: task
priority: high
created_at: 2026-04-28T05:36:05Z
updated_at: 2026-04-28T15:55:01Z
parent: ddi-wtv
sync:
    github:
        issue_number: "496"
        synced_at: "2026-04-28T16:43:52Z"
---

Implements the plan in `/Users/jason/.claude/plans/in-that-case-let-glittery-hopper.md`. Completes the conversion of the 18 rules deferred from clusters `5r3-peg` and `r0w-l4r` so that `dil-cew` (delete legacy) becomes a safe cleanup.

## Infrastructure

- [x] **A.** Add `Context.ruleState(for:initialize:)` per-file rule-state cache (`Sources/SwiftiomaticKit/Support/Context.swift`).
- [x] **B.** Extend `RuleCollector` + `CompactStageOneRewriterGenerator` to emit `willEnter` / `didExit` hooks before/after `super.visit` for any rule that opts in.

## Batch 1 — trivial (pure static, no infra)

- [x] `Idioms/NoVoidTernary` (already ported)
- [ ] `Idioms/PreferExplicitFalse` warning: reverted from git after triage; re-port needed
- [x] `Idioms/NoAssignmentInExpressions`
- [ ] `Declarations/OneDeclarationPerLine` warning: reverted from git after triage; re-port needed
- [x] `Declarations/ProtocolAccessorOrder`
- [ ] `Redundancies/NoSemicolons` warning: reverted from git after triage; re-port needed
- [ ] `Wrap/WrapSingleLineBodies` warning: reverted from git after triage; re-port needed

## Batch 2 — moderate (Context.ruleState)

- [x] `Idioms/LeadingDotOperators`
- [x] `Literals/URLMacro` (uses willEnter for pre-scan)
- [x] `Redundancies/RedundantAccessControl` (uses willEnter for file-structure analysis)
- [x] `Testing/TestSuiteAccessControl`
- [x] `Testing/SwiftTestingTestCaseNames`
- [x] `Testing/ValidateTestCases`
- [x] `Testing/NoGuardInTests` (uses willEnter/didExit for class+function scope)
- [x] `Testing/PreferSwiftTesting` (uses willEnter/didExit for class+extension+function scope)

## Batch 3 — hard (scope hooks + post-walk)

- [ ] `Idioms/PreferSelfType` (willEnter/didExit on type decls)
- [ ] `Redundancies/RedundantSelf` (willEnter/didExit on every scope-opening decl)
- [ ] `Idioms/PreferEnvironmentEntry` (file-level pre-scan via Context.ruleState)

## Verification

After each rule:
- `xc-swift swift_diagnostics --build-tests` — clean
- `xc-swift swift_package_test --filter CompactPipelineParityTests` — green (byte-identical to legacy)

After Batch 3:
- `xc-swift swift_package_test` — full suite green

## Done when

All 18 rules expose the static-transform contract (with `Context.ruleState` and/or `willEnter`/`didExit` where needed). `CompactPipelineParityTests` stays green throughout. `dil-cew` becomes safe to execute.



## Triage notes (2026-04-28)

### What happened

Batch 1 agent over-simplified the legacy `override func visit` paths in 5 rules - dropped manual `rewrite(Syntax(item))` recursions and `super.visit` calls that were doing real work for the unit-test code path. The 3-fixture golden corpus didn't exercise the affected behavior, so `CompactPipelineParityTests` stayed green while the 191 rule-specific unit tests went red. Full test suite went from clean to 50 failures (later confirmed 48 caused by Batch 1 + 2 unrelated `GuardStmtTests` idempotence failures).

### Resolution

Reverted the 5 affected files from commit `8b7135e2` (pre-port baseline) and re-ran the suite: 3022 passed, 2 failed. Both remaining failures (`GuardStmtTests/breaksElseWhenInlineBodyExceedsLineLength`, `optionalBindingConditions`) are layout/pretty-printer idempotence issues with no connection to any rule file modified in this work - they predate the deferred-rule port and should be tracked separately.

### Files reverted

- `Sources/SwiftiomaticKit/Rules/Redundancies/NoSemicolons.swift`
- `Sources/SwiftiomaticKit/Rules/Declarations/OneDeclarationPerLine.swift`
- `Sources/SwiftiomaticKit/Rules/Wrap/WrapSingleLineBodies.swift`
- `Sources/SwiftiomaticKit/Rules/Idioms/PreferExplicitFalse.swift`
- `Sources/SwiftiomaticKit/Rules/Redundancies/RedundantReturn.swift` - bonus: broken in earlier cluster `r0w-l4r`, hidden until now

### Lesson for re-port

Do not modify the existing `override func visit` body. Add `static func transform` strictly alongside as a duplicate code path. The static transform is allowed to be simpler (no manual recursion) because the combined rewriter handles descendant traversal; the override must keep its full original logic so legacy unit tests stay green. Code duplication is the price of incremental migration.

### Re-port follow-up

5 rules need a careful re-port (preserving original override behavior, adding static transform alongside). Tracked above with warning markers. Defer until after Batch 3 + cutover dry-run, since these 5 currently work via legacy and the parity test catches any divergence.



## Phase 1 scope (per ddi-wtv collapse plan, 2026-04-28)

This issue now covers **only Phase 1** of the collapse plan: ensure every node-local rule has a working static `transform(_:parent:context:)`. Phases 2-4 (test retarget, default flip, legacy delete) are tracked in `ddi-wtv` directly.

### What changes for the remaining work

- **Batch 3 (3 rules)**: proceed as planned — `PreferSelfType`, `RedundantSelf`, `PreferEnvironmentEntry`. Uses existing `Context.ruleState` + `willEnter`/`didExit` infra.
- **5 reverted rules** (`NoSemicolons`, `OneDeclarationPerLine`, `WrapSingleLineBodies`, `PreferExplicitFalse`, `RedundantReturn`): **the "preserve original override behavior" constraint is dropped**. Write fresh static transforms only. The legacy override path is going away in Phase 4 — there is no longer a reason to keep duplicate logic to satisfy legacy unit tests, because those tests will be retargeted in Phase 2.
- **Verification**: parity test (`CompactPipelineParityTests`) green after each rule. Full suite divergence is acceptable here — the override path will not be exercised after Phase 3.

### Done when

All 18 rules expose static-transform contract. Parity test green. `ddi-wtv` Phase 2 can begin.



## Phase 1 scope (per ddi-wtv revised collapse plan, 2026-04-28)

This issue covers **only Phase 1** of the revised plan: ensure every node-local rule has a working static `transform(_:parent:context:)`. Phases 2-4 (test retarget, default flip, node-type merge + legacy delete) are tracked in `ddi-wtv` directly.

### What changes for the remaining work

- **Batch 3 (3 rules)**: proceed as planned — `PreferSelfType`, `RedundantSelf`, `PreferEnvironmentEntry`. Uses existing `Context.ruleState` + `willEnter`/`didExit` infra.
- **5 reverted rules** (`NoSemicolons`, `OneDeclarationPerLine`, `WrapSingleLineBodies`, `PreferExplicitFalse`, `RedundantReturn`): **the "preserve original override behavior" constraint is dropped**. Write fresh static transforms only. The legacy override path is going away in Phase 4 — no reason to keep duplicate logic to satisfy legacy unit tests, because those tests will be retargeted in Phase 2.
- **These static transforms are intermediate**: in Phase 4 they will be merged by node type into `Sources/SwiftiomaticKit/Rewrites/<Category>/<NodeType>.swift`. Don't optimize the per-rule files — they're disposable scaffolding.
- **Verification**: parity test (`CompactPipelineParityTests`) green after each rule. Full suite divergence is acceptable here — the override path will not be exercised after Phase 3.

### Done when

All 18 rules expose static-transform contract. Parity test green. `ddi-wtv` Phase 2 can begin.



## Phase 1 progress (2026-04-28)

**All 18 rules now expose static-transform contract.** Build clean; `CompactPipelineParityTests` green (1 passed, 0.419s).

### Batch 1 reverted rules — re-ported

- [x] `Idioms/PreferExplicitFalse` — added `transform(_:PrefixOperatorExprSyntax)`. **Minor divergence**: `isInsideIfConfigCondition` walks the captured parent chain and returns `true` whenever any ancestor is `IfConfigClauseSyntax` (in practice bare expressions only live in `condition` field). Legacy compares `condition.id == current.id` exactly.
- [x] `Declarations/OneDeclarationPerLine` — added `transform(_:EnumDeclSyntax)` and `transform(_:CodeBlockItemListSyntax)`; manual `super.visit` recursion dropped (children already visited).
- [x] `Redundancies/NoSemicolons` — added `transform(_:CodeBlockItemListSyntax)` and `transform(_:MemberBlockItemListSyntax)` plus `removingSemicolons` static helper.
- [x] `Wrap/WrapSingleLineBodies` — added static transforms for 10 node types. **Intentional divergence**: static `resolveIndent` falls back to `""` when trivia carries no newline; static `wrapIf` uses `""` as `baseIndent` for `isElseIf` (instance currentIndent/chainBaseIndent state isn't accessible statically). Nested same-line conditional output may differ slightly from legacy.
- [x] `Redundancies/RedundantReturn` — added `transform(_:FunctionDeclSyntax)`, `transform(_:SubscriptDeclSyntax)`, `transform(_:PatternBindingSyntax)`, `transform(_:ClosureExprSyntax)` plus full set of static analyzer/rewriter helpers.

### Batch 3 — completed

- [x] `Idioms/PreferSelfType` — `State { var typeDepth = 0 }`; `willEnter`/`didExit` for Class/Struct/Enum/Actor/Extension; `transform(_:MemberAccessExprSyntax)` gated on `typeDepth > 0`.
- [x] `Redundancies/RedundantSelf` — `State` mirrors three instance stacks (`referenceTypeStack`, `implicitSelfStack`, `localNameStack`) + `scopeFrameStack` for safe didExit popping; willEnter/didExit on 12 scope-opening decl types; `transform(_:MemberAccessExprSyntax)`.
- [x] `Idioms/PreferEnvironmentEntry` — `State { environmentKeys, matchedKeys }` (declared `private` — its members reference nested `private` `KeyInfo`); `willEnter(_:SourceFileSyntax)` runs file-level pre-scan; `transform(_:SourceFileSyntax)` performs the rewrite.

### Outstanding risk

The 3-fixture parity corpus stayed green throughout — but as flagged in the prior triage, the corpus doesn't exercise enough patterns to catch every divergence. The two flagged divergences (PreferExplicitFalse `isInsideIfConfigCondition`, WrapSingleLineBodies indent state) may surface during Phase 3 when full test suite runs against compact pipeline. Either fix at that time or accept (these specific paths get rewritten anyway in Phase 4 node-type merge).

### Phase 1 done

`ddi-wtv` Phase 2 (test harness retarget) can begin.



## Phase 1 completed (2026-04-28)

All 18 rules expose static-transform contract. Parity test green. Phase 4 sub-issues (49k-dtg, 95z-bgr, np6-piu, zvf-rsq, mn8-do3, 2sn-0al, dal-dmw) now unblocked. Per the revised plan (skip Phase 2/3, jump to Phase 4), the static transforms produced here are intermediate scaffolding that Phase 4 sub-issues merge into per-node-type functions.
