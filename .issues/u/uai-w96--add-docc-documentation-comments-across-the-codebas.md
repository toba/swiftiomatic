---
# uai-w96
title: Add DocC documentation comments across the codebase
status: completed
type: task
priority: normal
created_at: 2026-03-01T18:02:49Z
updated_at: 2026-03-01T18:20:48Z
sync:
    github:
        issue_number: "124"
        synced_at: "2026-03-01T18:21:07Z"
---

Add documentation comments to all public and internal types throughout the Swiftiomatic codebase. Standardize on short-form parameter documentation. Work section-by-section starting with foundational layers.

## Plan

Work through layers bottom-up so each layer's docs can reference already-documented types:

### Phase 1: Extensions (foundation utilities)
- [x] Extensions/ — String, Collection, SwiftSyntax helpers

### Phase 2: SourceKit layer
- [x] SourceKit/ — C bindings, type system enums, resolvers

### Phase 3: Support infrastructure  
- [x] Support/ root — Console, file discovery, glob, diagnostics
- [x] Support/Detectors/ — Pattern detectors
- [x] Support/Visitors/ — AST visitors

### Phase 4: Format engine
- [x] Format/ — Token, Tokenizer, Formatter, FormatOptions, FormatRule

### Phase 5: Rules infrastructure
- [x] Rules/ base protocols — Rule, ASTRule, CollectingRule
- [x] Rules/ category directories — top-level category docs

### Phase 6: Analysis & Public API
- [x] Suggest/ — Analyzer, TextFormatter (no changes needed)
- [x] PublicAPI.swift (no changes needed)

## Style Guide
- Use grouped parameter form: `- Parameters:` with `  - name: Description.`
- Summary line is a single sentence fragment (no period)
- Add `## Discussion` only when non-obvious
- Link related types with ```TypeName``` syntax
- Do NOT add docs to trivial computed properties or obvious enum cases


## Summary of Changes

Documented ~130 files across all layers of the codebase:
- **Extensions/** (35 files): Added DocC comments to all utility extensions, converted parameter style
- **SourceKit/** (31 files): Documented all SourceKit bindings, types, and resolvers
- **Support/** (29 files): Documented root utilities, detectors, and visitors
- **Format/** (19 files): Documented formatter, tokenizer, options, and rules infrastructure
- **Rules/** (14 root files) + **Configuration/** (8 files): Converted parameter style, added docs to undocumented types
- **Models/** (16 files): Converted all parameter docs to grouped form
- **Suggest/** + **PublicAPI.swift**: Already properly documented, no changes needed

All parameters now use the grouped `- Parameters:` form. Summaries are sentence fragments without trailing periods. Discussion sections added only where non-obvious.
