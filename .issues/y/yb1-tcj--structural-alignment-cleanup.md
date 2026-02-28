---
# yb1-tcj
title: Structural alignment cleanup
status: completed
type: task
priority: normal
created_at: 2026-02-28T01:48:33Z
updated_at: 2026-02-28T01:48:43Z
parent: 9q3-qlh
---

## Objective
Fix structural issues after consolidating three analysis engines into a single target.

## Tasks
- [x] Add missing `RuleKind` cases (suggest, concurrency, observation) — already done
- [x] Add `confidence` and `suggestion` to `ReasonedRuleViolation` — already done
- [x] Add `confidence` and `suggestion` to `StyleViolation` — already done
- [x] Wire `confidence`/`suggestion` through the violation pipeline (both makeViolation overloads)
- [x] Register all 12 ported rules in AllRules.swift
- [x] Delete dead Core/Extensions/ files — investigated, all 6 files are actively used, none deleted
- [x] Verify build and tests pass

## Notes
- The 6 extension files marked for deletion in the plan were all found to be actively used:
  - `Collection+Windows.swift` — used by `SwiftSyntax+SwiftLint.swift`
  - `SyntaxClassification+isComment.swift` — used by `PeriodSpacingRule` and `CommentSpacingRule`
  - `RandomAccessCollection+Swiftlint.swift` — used by `SwiftLintSyntaxMap.swift`
  - `StringView+SwiftSyntax.swift` — used by `SyntacticSugarRule`, `RedundantObjcAttributeRule`, `SwiftSyntaxCorrectableRule`
  - `SwiftSource+Regex.swift` — used by `CustomRules`, `UnusedImportRule`, `StatementPositionRule`, `Linter`
  - `SwiftSource+BodyLineCount.swift` — used by `BodyLengthVisitor.swift`


## Summary of Changes
- Registered 12 ported suggest rules in `AllRules.swift`: AgentReview, AnyElimination, ConcurrencyModernization, DeadSymbols, FireAndForgetTask, NamingHeuristics, ObservationPitfalls, PerformanceAntiPatterns, StructuralDuplication, Swift62Modernization, SwiftUILayout, TypedThrows
- Wired `confidence`/`suggestion` through the fallback `makeViolation` (non-SeverityBasedRuleConfiguration path)
- Removed "GENERATED FILE" comment from AllRules.swift
- Investigated 6 extension files for deletion — all are actively used, none deleted
