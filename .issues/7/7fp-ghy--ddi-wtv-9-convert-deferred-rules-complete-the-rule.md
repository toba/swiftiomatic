---
# 7fp-ghy
title: 'ddi-wtv-9: convert deferred rules; complete the rule port'
status: in-progress
type: task
priority: high
created_at: 2026-04-28T05:36:05Z
updated_at: 2026-04-28T05:36:05Z
parent: ddi-wtv
---

Implements the plan in `/Users/jason/.claude/plans/in-that-case-let-glittery-hopper.md`. Completes the conversion of the 18 rules deferred from clusters `5r3-peg` and `r0w-l4r` so that `dil-cew` (delete legacy) becomes a safe cleanup.

## Infrastructure

- [ ] **A.** Add `Context.ruleState(for:initialize:)` per-file rule-state cache (`Sources/SwiftiomaticKit/Support/Context.swift`). Unit-test that two files get distinct state.
- [ ] **B.** Extend `RuleCollector` + `CompactStageOneRewriterGenerator` to emit `willEnter` / `didExit` hooks before/after `super.visit` for any rule that opts in.

## Batch 1 — trivial (pure static, no infra)

- [ ] `Idioms/NoVoidTernary`
- [ ] `Idioms/PreferExplicitFalse`
- [ ] `Idioms/NoAssignmentInExpressions`
- [ ] `Declarations/OneDeclarationPerLine`
- [ ] `Declarations/ProtocolAccessorOrder`
- [ ] `Redundancies/NoSemicolons`
- [ ] `Wrap/WrapSingleLineBodies`

## Batch 2 — moderate (Context.ruleState)

- [ ] `Idioms/LeadingDotOperators`
- [ ] `Literals/URLMacro`
- [ ] `Redundancies/RedundantAccessControl`
- [ ] `Testing/TestSuiteAccessControl`
- [ ] `Testing/SwiftTestingTestCaseNames`
- [ ] `Testing/ValidateTestCases`
- [ ] `Testing/NoGuardInTests`
- [ ] `Testing/PreferSwiftTesting`

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
