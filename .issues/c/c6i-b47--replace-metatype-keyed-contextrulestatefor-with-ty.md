---
# c6i-b47
title: Replace metatype-keyed Context.ruleState(for:) with typed state properties
status: completed
type: task
priority: high
created_at: 2026-04-29T22:44:35Z
updated_at: 2026-04-29T23:24:59Z
parent: iv7-r5g
blocked_by:
    - 6ji-ue3
sync:
    github:
        issue_number: "513"
        synced_at: "2026-04-30T00:29:45Z"
---

## Goal

Replace the metatype-keyed `Context.ruleState(for:)` indirection with typed properties on `Context` — one property per stateful rewrite pass.

```swift
// before
let state = context.ruleState(for: NoForceTry.self) { NoForceTry.State() }

// after
context.noForceTryState  // typed, eagerly initialized
```

## Stateful rewrite passes (current consumers)

- `NoForceTry.State`
- `NoForceUnwrap.State` (+ `ChainTopContext`)
- `RedundantSelf` state
- `NamedClosureParams.State`
- `PreferFinalClasses.State`
- `RedundantSwiftTestingSuite` state
- `RedundantEscaping` state

(Audit at start of work — cross-reference any remaining `context.ruleState(for:` callers.)

## Approach

1. Add typed lazy/eager-initialized properties on `Context` (one per stateful rule). Property name + type lives next to the rule, owned by Context.
2. Replace each `context.ruleState(for: Foo.self) { Foo.State() }` callsite with `context.fooState`.
3. Delete `Context.ruleState(for:)` and the underlying metatype-keyed dictionary.

## Context

Follow-up from `wru-y41`. The compact pipeline closed the rule set, so metatype-keyed state lookup is overhead — direct typed properties are simpler and faster.

## Out of scope

- `applyRule` ladder cleanup (separate follow-up `6ji-ue3`).
- Structural-pass rule migration off `RewriteSyntaxRule` (separate follow-up).

## Verification bar

- `xc-swift swift_diagnostics --no-include-lint` clean at the 12-warning baseline.
- Full test suite parity (2 pre-existing pretty-printer failures remain).



## Summary of Changes

Replaced the metatype-keyed `Context.ruleState(for:)` indirection with 18 typed `lazy var` properties on `Context` — one per stateful compact-pipeline rewrite.

### What landed

- **`Context` gains 18 typed lazy properties** (`hoistTryState`, `leadingDotOperatorsState`, `namedClosureParamsState`, `noForceTryState`, `noForceUnwrapState`, `noGuardInTestsState`, `preferEnvironmentEntryState`, `preferFinalClassesState`, `preferSelfTypeState`, `preferSwiftTestingState`, `redundantAccessControlState`, `redundantSelfState`, `redundantSwiftTestingSuiteState`, `swiftTestingTestCaseNamesState`, `testSuiteAccessControlState`, `urlMacroState`, `validateTestCasesState`, `wrapSingleLineBodiesState`).
- **`Context.ruleState(for:initialize:)` deleted** along with `ruleStateStorage` (`[ObjectIdentifier: AnyObject]`) and `ruleStateLock` (`NSLock`). Each Context is per-file and processed sequentially, so the lock was defensive and unnecessary; `lazy var` is sufficient.
- **87 callsites mass-converted** via regex:
  `context.ruleState(for: <T>.self) { <S>() }` → `context.<rule>State` across 18 rule files.
- **`PreferEnvironmentEntry.State`** widened from `private` to internal so `Context` can store it; `KeyInfo` and `DefaultValue` widened similarly (transitive).
- **18 doc-comment references** updated from `Context.ruleState` to "a typed lazy property on `Context`".

### Verification

- `xc-swift swift_diagnostics --no-include-lint` clean (11 warnings, baseline).
- 3,009 tests pass; only the 2 pre-existing pretty-printer-idempotency failures remain.

### Net diff

- `Sources/SwiftiomaticKit/Support/Context.swift` — 18 lazy properties added; dictionary + lock + `ruleState(for:)` removed.
- 18 rule files in `Sources/SwiftiomaticKit/Rules/` — callsites migrated.
- `Sources/SwiftiomaticKit/Rules/Idioms/PreferEnvironmentEntry.swift` — access widening on `State` + nested types.
