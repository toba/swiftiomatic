---
# x2t-qmw
title: Make weak var → weak let auto-correctable in Swift62ModernizationRule
status: completed
type: task
priority: normal
created_at: 2026-03-03T01:34:23Z
updated_at: 2026-03-03T01:42:38Z
sync:
    github:
        issue_number: "159"
        synced_at: "2026-03-03T01:43:42Z"
---

Add reassignment detection and auto-correction for weak var → weak let in Swift62ModernizationRule.

## Tasks
- [x] Add `static let isCorrectable = true`
- [ ] Change conformance from SwiftSyntaxRule to SwiftSyntaxCorrectableRule
- [ ] Add ReassignmentFinder helper to detect reassignments in containing scope
- [ ] Update visitPost for weak var to use reassignment detection and produce corrections
- [ ] Update examples with triggering/non-triggering cases
- [ ] Build and verify
- [ ] Run tests

## Summary of Changes

### Swift62ModernizationRule.swift
- Added `static let isCorrectable = true`
- Changed conformance from `SwiftSyntaxRule` to `SwiftSyntaxCorrectableRule`
- Added reassignment detection via `searchForAssignment` that recursively walks the containing scope (CodeBlockSyntax, MemberBlockSyntax, or SourceFileSyntax) looking for `SequenceExprSyntax` and `InfixOperatorExprSyntax` assignment patterns matching the binding name
- Skips `weak var` with property observers (didSet/willSet) since `let` doesn't support observers
- Non-reassigned weak vars now produce a `SyntaxViolation.Correction` that replaces `var` → `let`, with confidence raised to `.medium`
- Reassigned weak vars are silently skipped (no violation)
- Added triggering and non-triggering examples

### Swift62ModernizationTests.swift
- Added `detectsWeakVarNotReassigned` test verifying correct count and filtering

### SuggestFixtures/Swift62Modernization.swift
- Added 5 fixture cases: non-reassigned property, reassigned property, property with observer, non-reassigned local, reassigned local
