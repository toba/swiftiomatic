---
# yr7-zbm
title: 'Phase 1: Migrate semantic format rules to AST'
status: completed
type: task
priority: normal
created_at: 2026-03-01T00:58:57Z
updated_at: 2026-03-01T05:33:53Z
parent: aku-gm2
sync:
    github:
        issue_number: "98"
        synced_at: "2026-03-01T06:13:20Z"
---

Migrate rules that perform semantic/structural analysis from token-based closures to SwiftSyntaxRule / SwiftSyntaxCorrectableRule. These rules are fighting the flat token model — they parse declarations, track scopes, and resolve references, all of which swift-syntax provides natively.

## Redundancy rules (28)

- [x] redundantReturn
- [x] redundantSelf
- [x] redundantInit
- [x] redundantGet
- [x] redundantLet
- [x] redundantLetError
- [x] redundantNilInit
- [x] redundantBreak
- [x] redundantParens
- [x] redundantPattern
- [x] redundantBackticks
- [x] redundantAsync
- [x] redundantThrows
- [x] redundantTypedThrows
- [x] redundantVoidReturnType
- [x] redundantType
- [x] redundantRawValues
- [x] redundantProperty
- [x] redundantClosure
- [x] redundantOptionalBinding
- [x] redundantEquatable
- [x] redundantObjc
- [x] redundantInternal
- [x] redundantPublic
- [x] redundantFileprivate
- [x] redundantExtensionACL
- [x] redundantStaticSelf
- [x] redundantMemberwiseInit
- [x] redundantViewBuilder

## Hoisting rules (3)

- [x] hoistPatternLet
- [x] hoistTry
- [x] hoistAwait

## Preference / conditional rules (7)

- [x] conditionalAssignment
- [x] preferForLoop
- [x] preferKeyPath
- [x] preferCountWhere
- [x] preferFinalClasses
- [x] yodaConditions
- [x] preferSwiftTesting

## Notes

- Start with simpler rules (redundantReturn, redundantGet, redundantBreak) to establish the migration pattern
- redundantSelf is the most complex — save for last
- Each rule: implement as SwiftSyntaxCorrectableRule, verify against existing tests, disable token version


## Summary of Changes

All 38 semantic format rules migrated to AST-based SwiftSyntaxRule / SwiftSyntaxCorrectableRule. 20 new rule implementations created, 18 pre-existing. All registered in RuleRegistry+AllRules.swift. All tests pass.
