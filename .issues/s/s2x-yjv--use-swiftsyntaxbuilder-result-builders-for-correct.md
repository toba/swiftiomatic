---
# s2x-yjv
title: Use SwiftSyntaxBuilder result builders for correction node construction
status: completed
type: task
priority: low
created_at: 2026-04-12T23:54:23Z
updated_at: 2026-04-13T00:51:03Z
parent: oad-n72
sync:
    github:
        issue_number: "251"
        synced_at: "2026-04-13T00:55:42Z"
---

SwiftSyntaxBuilder's `ListBuilder` result builder enables DSL-style construction of replacement syntax nodes. Could simplify `ViolationCollectingRewriter` subclasses that build replacement AST fragments.

## Reference

`SwiftSyntaxBuilder/ListBuilder.swift`:
- `ListBuilder` protocol with `buildBlock`, `buildExpression`, `buildOptional`, `buildEither`, `buildArray`
- Auto-inserts trailing commas for `WithTrailingCommaSyntax` elements
- Generated result builders for each syntax collection type

## Applicability

Most corrections are simple text replacements where this adds no value. Useful for rules that construct complex replacement nodes (e.g., adding new parameters, restructuring function signatures, wrapping expressions).

## Tasks

- [x] Identify correctable rules that construct multi-node replacements
- [x] Refactor 1-2 rewriter subclasses — evaluated, not beneficial
- [x] Evaluate readability improvement vs. current string/node construction


## Summary of Changes

Evaluated SwiftSyntaxBuilder result builders against our correction patterns.

### Assessment

**Current correction patterns (80 Rewriter-based rules):**
- ~90% do simple token/trivia edits: swap token kind, remove trailing trivia, insert/remove tokens
- These are now well-served by the `Correction` enum variants from se8-7qh (`.replaceNode`, `.replaceTrailingTrivia`, `.replaceLeadingTrivia`)
- ~10% construct multi-node replacements (list reordering, modifier insertion) using `.with()` API

**Why pass:**
1. SwiftSyntaxBuilder's `ListBuilder` is designed for constructing new trees from scratch (macro expansion), not surgical edits
2. Our Rewriters modify existing trees via `.with()` — this is more natural than building replacement trees from scratch with result builders
3. The few multi-node cases (e.g., `ModifierOrderRule`, `TrailingCommaRule`) use `.with()` effectively; SwiftSyntaxBuilder would be a different (not simpler) syntax
4. No measurable readability improvement — result builders add abstraction without reducing complexity for edit-style operations

**Decision: pass** — our `.with()` + new `Correction` enum variants cover the space well.
