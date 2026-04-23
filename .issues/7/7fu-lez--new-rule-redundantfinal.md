---
# 7fu-lez
title: 'New rules: RedundantFinal + PreferStaticOverClassFunc'
status: completed
type: feature
priority: normal
created_at: 2026-04-23T15:34:19Z
updated_at: 2026-04-23T15:52:32Z
sync:
    github:
        issue_number: "356"
        synced_at: "2026-04-23T16:14:37Z"
---

Port SwiftLint's `redundant_final` concept (realm/SwiftLint#6597, commit f242859).

## Description

Flag `final` on members of `final` classes, since all members are implicitly final. Also flag `class func` in final classes — should be `static func`.

## Cases to detect

- `final func f()` inside a `final class` → remove `final`
- `final var x: Int` inside a `final class` → remove `final`
- `class func f()` inside a `final class` → suggest `static func`

## Implementation

- [x] Create `RedundantFinal` as `RewriteSyntaxRule`
- [x] Walk `ClassDeclSyntax` nodes; check if class has `final` modifier
- [x] Split into two rules: `RedundantFinal` (removes `final`) and `PreferStaticOverClassFunc` (replaces `class` with `static`)
- [x] Add tests (11 for RedundantFinal, 9 for PreferStaticOverClassFunc)
- [x] No conflict — PreferFinalClasses adds `final` to classes; these rules clean up members inside final classes

## References

- SwiftLint `redundant_final`: realm/SwiftLint commit f242859
- SwiftLint `static_over_final_class`: existing related rule
- Our `PreferFinalClasses` rule (inverse direction)

Originated from citation review uci-eqt.



## Summary of Changes

- Created `RedundantFinal` — removes redundant `final` from members of final classes
- Created `PreferStaticOverClassFunc` — replaces `class` with `static` on members of final classes
- Both are `RewriteSyntaxRule<BasicRuleValue>` in the `redundancies` group, default `rewrite: false, lint: .warn`
- Fixed `removingModifiers` helper to not clobber leading trivia when removing a non-first modifier
- Fixed `enableRule(named:)` to also match by short key (was only matching qualified keys, breaking all grouped rule tests)
