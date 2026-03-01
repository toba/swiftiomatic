---
# aku-gm2
title: Migrate format rules from token-based to AST-based (swift-syntax)
status: ready
type: epic
created_at: 2026-03-01T00:58:44Z
updated_at: 2026-03-01T00:58:44Z
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
