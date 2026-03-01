---
# yr7-zbm
title: 'Phase 1: Migrate semantic format rules to AST'
status: in-progress
type: task
priority: normal
created_at: 2026-03-01T00:58:57Z
updated_at: 2026-03-01T04:17:14Z
parent: aku-gm2
sync:
    github:
        issue_number: "98"
        synced_at: "2026-03-01T04:54:04Z"
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
- [ ] redundantParens
- [x] redundantPattern
- [ ] redundantBackticks
- [x] redundantAsync
- [x] redundantThrows
- [x] redundantTypedThrows
- [x] redundantVoidReturnType
- [ ] redundantType
- [ ] redundantRawValues
- [ ] redundantProperty
- [ ] redundantClosure
- [ ] redundantOptionalBinding
- [ ] redundantEquatable
- [ ] redundantObjc
- [ ] redundantInternal
- [ ] redundantPublic
- [ ] redundantFileprivate
- [ ] redundantExtensionACL
- [ ] redundantStaticSelf
- [ ] redundantMemberwiseInit
- [ ] redundantViewBuilder

## Hoisting rules (3)

- [x] hoistPatternLet
- [ ] hoistTry
- [ ] hoistAwait

## Preference / conditional rules (7)

- [ ] conditionalAssignment
- [ ] preferForLoop
- [ ] preferKeyPath
- [ ] preferCountWhere
- [ ] preferFinalClasses
- [ ] yodaConditions
- [ ] preferSwiftTesting

## Notes

- Start with simpler rules (redundantReturn, redundantGet, redundantBreak) to establish the migration pattern
- redundantSelf is the most complex — save for last
- Each rule: implement as SwiftSyntaxCorrectableRule, verify against existing tests, disable token version
