---
# s2x-yjv
title: Use SwiftSyntaxBuilder result builders for correction node construction
status: ready
type: task
priority: low
created_at: 2026-04-12T23:54:23Z
updated_at: 2026-04-12T23:54:23Z
parent: oad-n72
sync:
    github:
        issue_number: "251"
        synced_at: "2026-04-13T00:25:21Z"
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

- [ ] Identify correctable rules that construct multi-node replacements
- [ ] Refactor 1-2 rewriter subclasses to use SwiftSyntaxBuilder DSL
- [ ] Evaluate readability improvement vs. current string/node construction
