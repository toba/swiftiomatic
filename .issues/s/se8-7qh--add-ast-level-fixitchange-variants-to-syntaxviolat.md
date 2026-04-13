---
# se8-7qh
title: Add AST-level FixIt.Change variants to SyntaxViolation.Correction
status: completed
type: feature
priority: high
created_at: 2026-04-12T23:54:23Z
updated_at: 2026-04-13T00:10:14Z
parent: oad-n72
sync:
    github:
        issue_number: "243"
        synced_at: "2026-04-13T00:25:21Z"
---

`SyntaxViolation.Correction` is purely byte-range-based (`start`, `end`, `replacement` string). swift-syntax's `FixIt.Change` enum offers richer structural operations that would simplify rule authoring and reduce position-calculation bugs.

## Reference

`SwiftDiagnostics/FixIt.swift` — `FixIt.Change` enum:
- `.replace(oldNode:newNode:)` — structural replacement with smart trivia preservation (auto-detects matching leading/trailing trivia and narrows the edit range, lines 129-139)
- `.replaceLeadingTrivia(token:newTrivia:)` — trivia-only edits without touching content
- `.replaceTrailingTrivia(token:newTrivia:)` — trivia-only edits
- `.replaceChild(data:)` — type-safe parent-child replacement via `ReplacingChildData` protocol

## Tasks

- [x] Extend `SyntaxViolation.Correction` (or add new enum) with AST-level variants
- [x] Add trivia replacement variants for format-scope rules
- [x] Add node replacement variant with smart trivia preservation
- [x] Update correction application to handle new variant types
- [x] Migrate 2-3 format rules to use trivia variants as proof of concept
- [x] Verify all existing correction examples still pass


## Summary of Changes

Converted `SyntaxViolation.Correction` from a flat struct (start/end/replacement) to an enum with four variants:
- `.textReplacement` — original byte-range model, backward-compatible via `init(start:end:replacement:)`
- `.replaceNode` — structural node swap with smart trivia preservation (from swift-syntax FixIt.Change)
- `.replaceLeadingTrivia` / `.replaceTrailingTrivia` — trivia-only edits on tokens

Added `resolved` property that flattens any variant to a byte range for the correction applicator.

Migrated 3 rules as proof of concept:
- `AttributeNameSpacingRule` → `.replaceTrailingTrivia` (eliminates manual position math)
- `PreferWeakLetRule` → `.replaceNode` (token keyword swap)
- `SwiftModernizationRule` → `.replaceNode` (same pattern)

All existing correction examples pass.
