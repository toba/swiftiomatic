---
# 31c-hnd
title: Consolidate correction mechanisms from 3 to 2
status: completed
type: task
priority: normal
created_at: 2026-03-02T21:40:56Z
updated_at: 2026-03-02T23:10:18Z
parent: a2a-2wk
sync:
    github:
        issue_number: "141"
        synced_at: "2026-03-02T23:47:36Z"
---

Eliminate `SubstitutionCorrectableRule`, keeping only `ViolationCollectingRewriter` and `SyntaxViolation.Correction` ranges.

## Current State
Three correction mechanisms:
1. `ViolationCollectingRewriter` — SyntaxRewriter subclass, returns new nodes (for complex tree rewrites)
2. `SyntaxViolation.Correction` — position-based ranges with replacement string (for simple replacements)
3. `SubstitutionCorrectableRule` — `violationRanges()` + `substitution(for:in:)` using String.Index ranges

Mechanism 3 is redundant with mechanism 2 — both do range-based string replacement, just with different APIs.

## Target State
- Delete `SubstitutionCorrectableRule` protocol
- Migrate all conforming rules to use `SyntaxViolation.Correction` (mechanism 2) instead
- Two clear paths: rewriter for complex tree transforms, correction ranges for simple replacements

## Tasks
- [x] Identify all `SubstitutionCorrectableRule` conformers (5 rules: ColonRule, CommaInheritanceRule, RedundantObjcAttributeRule, CommentSpacingRule, PeriodSpacingRule)
- [x] Migrate each to produce `SyntaxViolation.Correction` in their visitor
- [x] Delete `SubstitutionCorrectableRule` protocol and related infrastructure
- [x] Update tests for migrated rules


## Summary of Changes

Eliminated the `SubstitutionCorrectableRule` protocol entirely. Migrated all 5 conforming rules:

1. **ColonRule** → `SwiftSyntaxCorrectableRule` with a `ViolationCollectingVisitor` that uses pre-order `visit()` to collect skip/dictionary/case positions and `visitPost(TokenSyntax)` to check each colon. Now pipeline-eligible.
2. **CommaInheritanceRule** → `SwiftSyntaxCorrectableRule` with `ViolationCollectingVisitor` that embeds `SyntaxViolation.Correction` for each ampersand in inheritance lists. Now pipeline-eligible.
3. **RedundantObjcAttributeRule** → `SwiftSyntaxCorrectableRule` (was already `SwiftSyntaxRule`). Correction now computed in the visitor using next-token position for trailing whitespace removal.
4. **CommentSpacingRule** → `CorrectableRule` with inlined `correct(file:)` (regex-based, not AST-visitor based).
5. **PeriodSpacingRule** → `CorrectableRule` with inlined `correct(file:)` (regex-based).

Deleted the `SubstitutionCorrectableRule` protocol and its default `correct(file:)` extension from Rule.swift. Regenerated lint pipeline: 292 SwiftSyntax rules (+3), 281 pipeline-eligible (+3). All 4350 tests pass.
