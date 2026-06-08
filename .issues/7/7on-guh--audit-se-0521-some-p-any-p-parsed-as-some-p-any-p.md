---
# 7on-guh
title: 'Audit: SE-0521 ''some P?'' / ''any P?'' parsed as ''(some P)?'' / ''(any P)?'''
status: deferred
type: task
priority: normal
created_at: 2026-06-08T19:41:55Z
updated_at: 2026-06-08T19:52:42Z
sync:
    github:
        issue_number: "725"
        synced_at: "2026-06-08T19:59:32Z"
---

Upstream swift-syntax change (swiftlang/swift-syntax #3268, merged 6d41eb59, 2026-06-07) implements SE-0521: 'some P?' parses as '(some P)?' and 'any P?' as '(any P)?'.

Reference: ~/Developer/swiftiomatic-ref/swift-syntax/Sources/SwiftParser/Types.swift

Audit Swiftiomatic rules that inspect SomeOrAnyTypeSyntax / OptionalTypeSyntax to ensure they continue to match correctly under the new parse shape. May affect any rule that walks optional/existential type structure.



## Deferral Notes

swift-syntax is pinned at 603.0.1 in Package.resolved (per the recent dep-bump commit, which deliberately held it back from 604+). SE-0521's parse change (`some P?` → `(some P)?`, `any P?` → `(any P)?`) only takes effect when Swiftiomatic upgrades past the SE-0521-implementing swift-syntax tag.

Audit scope (deferred until swift-syntax upgrade):
- `Sources/SwiftiomaticKit/Rules/Idioms/NoOptionalCollection.swift` (visits `OptionalTypeSyntax`)
- `Sources/SwiftiomaticKit/Rules/Idioms/NoOptionalBool.swift` (visits `OptionalTypeSyntax`)
- `Sources/SwiftiomaticKit/Rules/Idioms/NoImplicitlyUnwrappedOptionals.swift` (`ImplicitlyUnwrappedOptionalTypeSyntax`)
- `Sources/SwiftiomaticKit/Rules/Idioms/DropRedundantNilInit.swift` (`OptionalTypeSyntax`/`ImplicitlyUnwrappedOptionalTypeSyntax`)
- `Sources/SwiftiomaticKit/Rules/Idioms/UseSomeForGenericParameters.swift` (constructs/inspects `SomeOrAnyTypeSyntax`; highest risk — may need to handle new parent wrapping)
- `Sources/SwiftiomaticKit/Rules/Declarations/DropRedundantLet.swift` (`SomeOrAnyTypeSyntax` for `some View`)
- `Sources/SwiftiomaticKit/Rules/Sort/SortTypeAliases.swift` (`SomeOrAnyTypeSyntax` unwrap; second highest risk)
- `Sources/SwiftiomaticKit/Rules/Idioms/NoMutableInCaptureList.swift` (`ImplicitlyUnwrappedOptionalTypeSyntax`)
- `Sources/SwiftiomaticKit/Rules/Idioms/NoFormatterInViewBody.swift` (`SomeOrAnyTypeSyntax` for `some View`)
- `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Bindings.swift:231` (formats `some`/`any` keyword spacing)

Resume when the swift-syntax pin is moved. The two highest-risk rules (`UseSomeForGenericParameters`, `SortTypeAliases`) construct or unwrap `SomeOrAnyTypeSyntax` directly; under the new parse `some P?` becomes `OptionalTypeSyntax(wrappedType: SomeOrAnyTypeSyntax(...))` instead of the old `SomeOrAnyTypeSyntax(constraint: OptionalTypeSyntax(...))` shape, so any code that built or matched the outer layer needs revisiting.
