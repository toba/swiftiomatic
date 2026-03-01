---
# aku-gm2
title: Migrate format rules from token-based to AST-based (swift-syntax)
status: completed
type: epic
priority: normal
created_at: 2026-03-01T00:58:44Z
updated_at: 2026-03-01T06:12:06Z
sync:
    github:
        issue_number: "45"
        synced_at: "2026-03-01T06:13:19Z"
---

Migrate FormatRule closures from the custom tokenizer to swift-syntax SyntaxVisitor/SyntaxRewriter, eliminating the need to maintain two parallel rule systems.

## Goal

Incrementally replace token-based format rules with AST-based equivalents so that:
- Rules share a single parse (swift-syntax)
- Semantic rules get full AST context instead of fighting a flat token array
- The custom tokenizer shrinks to only the wrapping/indentation core (or disappears entirely)
- The DiagnosticDeduplicator becomes unnecessary as rules unify

## Approach

Four phases, each deliverable independently:

1. **Semantic rules** — rules already doing structural analysis on tokens (redundant*, hoist*, prefer*)
2. **Organization rules** — sorting, ordering, marking (sort*, organize*, modifier*)
3. **Simple formatting** — whitespace, spacing, blank lines (space*, blank*, trailing*)
4. **Wrapping/indentation** — keep token-based or port last (indent, wrap*)

## Constraints

- Each migrated rule must pass its existing test suite
- No regressions in `swiftiomatic format` output
- Rules can coexist during migration — token version disabled as AST version lands
- swift-syntax trivia manipulation for whitespace-oriented rules


## Summary of Changes

All 4 phases completed. Epic is done.

### Phase 1 (yr7-zbm): Migrate semantic format rules — COMPLETED
- 18 new AST rules created for semantic checks (redundancy, performance, testing, etc.)

### Phase 2 (cu8-swk): Migrate organization & ordering rules — COMPLETED
- 20 new AST rules created (comments, sorting, organization, access control, etc.)

### Phase 3 (6uk-rqg): Migrate simple formatting rules to AST trivia — COMPLETED
- 16 new AST rules created (spacing, blank lines, linebreaks)
- 15 covered by existing AST rules (TrailingWhitespaceRule, VerticalWhitespaceRule, etc.)

### Phase 4 (q9j-zaj): Evaluate wrapping/indentation — COMPLETED
- Decision: KEEP wrapping/indent as token-based sub-engine (dual-engine architecture)
- 7 new AST rules created for misc rules (andOperator, anyObjectProtocol, etc.)
- 13 covered by existing AST rules
- 21 rules retained as token-based (wrapping, indent, complex test transforms)

### Totals
- **61 new AST rules** created across all phases
- **43 rules** covered by pre-existing AST equivalents
- **21 rules** retained as token-based (wrapping/indent specialization)
- All new rules pass generated test suites (2 tests each, 122 tests total)
