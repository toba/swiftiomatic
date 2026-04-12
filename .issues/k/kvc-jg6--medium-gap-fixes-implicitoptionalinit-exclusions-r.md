---
# kvc-jg6
title: 'Medium gap fixes: ImplicitOptionalInit exclusions, RedundantType @Model/ternary'
status: completed
type: task
priority: high
created_at: 2026-04-12T21:38:55Z
updated_at: 2026-04-12T21:55:06Z
parent: a9u-qgt
sync:
    github:
        issue_number: "236"
        synced_at: "2026-04-12T22:20:45Z"
---

Implement medium logic gaps from audit epic a9u-qgt:

## ImplicitOptionalInitialization
- [x] Codable/Decodable type exclusion — don't remove `= nil` in Codable types (changes decoding behavior)
- [x] Result builder context exclusion — don't remove `= nil` inside result builder blocks
- [x] Swift < 5.2 struct memberwise init — N/A, we target Swift 6.3+; mark checked

## RedundantTypeAnnotation
- [x] `@Model` class exclusion — SwiftData requires explicit type annotations
- [x] Ternary expression detection — don't flag `let x: Foo = condition ? .a : .b` as redundant

## Deferred (config-only, not bugs)
EmptyBraces spaced/linebreak modes, Void configurable option, inferLocalsOnly — cosmetic config enhancements, not false-positive fixes.


## Summary of Changes

### ImplicitOptionalInitialization
- Added `isStoredPropertyInCodableType` — walks up to enclosing type, checks inheritance for Codable/Decodable. Only applies to stored properties (member-level), not local variables.
- Added `isInResultBuilderContext` — walks up to nearest function/property, checks for attributes ending in "Builder".
- Swift < 5.2 exclusion marked N/A (we target Swift 6.3+).
- Added 6 nonTriggeringExamples covering both styles.

### RedundantTypeAnnotation
- Added `isInModelType` — checks enclosing class for @Model attribute (SwiftData requirement).
- Ternary already handled implicitly (TernaryExprSyntax returns empty `accessedNames`), added nonTriggeringExample for documentation.
- Added 2 nonTriggeringExamples.
