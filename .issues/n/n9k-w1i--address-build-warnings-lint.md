---
# n9k-w1i
title: Address build warnings (lint)
status: completed
type: task
priority: normal
created_at: 2026-05-02T23:14:23Z
updated_at: 2026-05-03T03:06:48Z
sync:
    github:
        issue_number: "639"
        synced_at: "2026-05-03T03:11:04Z"
---

Fix lint warnings from Build sm_2026-05-02 log, excluding comment-related ones.

- [x] noParensAroundConditions: TokenStream+Closures.swift:200,201
- [x] noImplicitlyUnwrappedOptionals: WhitespaceLinter.swift:211,236
- [x] useNonOptionalDataInit: ConfigurationSchema+Generated.swift (generator change)
- [x] wrapTernaryBranches: TokenStream+ControlFlow.swift:26
- [x] useReduceInto: Trivia+Convenience.swift:162
- [x] useFirstWhere: DropRedundantReturn.swift:120
- [x] dropRedundantClosureWrapper: NoCaseNamedNone.swift
- [x] noImplicitlyUnwrappedOptionals: SplitMultipleDeclsPerLine.swift:261
- [x] useCommaNotAndInConditions: RuleMask.swift:250
- [x] Sendable capture warnings: Configuration.swift:107,111,113
- [x] deprecated init: DropRedundantSetterACL.swift:108
- [x] popLast unused result: LayoutSingleLineBodies.swift:974,988,1002,1016,1030



## Summary of Changes

Addressed all 20 non-comment lint warnings from the build log:

- `TokenStream+Closures.swift`: dropped parens around boolean conditions
- `WhitespaceLinter.swift`: replaced `ArraySlice!` IUOs with optionals + `?? 0` at use sites
- `ConfigurationSchemaSwiftGenerator.swift` + `ConfigurationSchema+Generated.swift`: switched embedded JSON decode to `Data(string.utf8)`
- `TokenStream+ControlFlow.swift`: wrapped ternary onto multiple lines
- `Trivia+Convenience.swift`: converted `.reduce` to `.reduce(into:)` for COW seed
- `DropRedundantReturn.swift`: collapsed `filter { ... }.first` into `first(where:)`
- `NoCaseNamedNone.swift`: replaced immediately-invoked closure with `if`/`else if`/`else` expression
- `SplitMultipleDeclsPerLine.swift`: replaced `varDecl: VariableDeclSyntax!` with optional + chained access
- `RuleMask.swift`: replaced `&&` with `,` in if-condition
- `Configurable.swift`: required `Sendable` conformance — fixes the three `C.Type` capture warnings in `Configuration.swift`
- `DropRedundantSetterACL.swift`: dropped redundant `DeclModifierListSyntax(_:)` round-trip
- `LayoutSingleLineBodies.swift`: discarded all five `popLast()` results with `_ =`

Clean build + `swift_diagnostics` run after: 1 unrelated warning remains; original 20 all gone.
