---
# y8r-1uz
title: Add diagnostic highlights and notes to RuleViolation
status: completed
type: feature
priority: normal
created_at: 2026-04-12T23:54:23Z
updated_at: 2026-04-13T00:36:23Z
parent: oad-n72
sync:
    github:
        issue_number: "252"
        synced_at: "2026-04-13T00:55:43Z"
---

`RuleViolation` has only a single position. swift-syntax's `Diagnostic` supports `highlights: [Syntax]` (regions to underline) and `notes: [Note]` (related locations with explanatory messages).

## Reference

`SwiftDiagnostics/Diagnostic.swift`:
- `highlights: [Syntax]` — additional syntax regions to underline in the editor
- `notes: [Note]` — related locations with explanatory `NoteMessage` (e.g., "declared here", "inferred type is X")

## Use Cases

- Unused declaration: highlight both the declaration and its expected usage site
- Redundant type annotation: point to the inferred type source
- Cross-file rules: note pointing to the other file's declaration
- Suggest rules: highlight the pattern being flagged and the replacement location

## Tasks

- [x] Add optional `highlights` field to `SyntaxViolation` or `RuleViolation`
- [x] Add optional `notes` field with position + message pairs
- [x] Propagate highlights/notes through `RuleViolation` → `Diagnostic` pipeline
- [x] Update JSON output format to include highlights and notes
- [x] Add highlights to 2-3 rules as proof of concept


## Summary of Changes

Added `highlights` and `notes` fields at every layer of the diagnostic pipeline:

- **`SyntaxViolation`**: `highlights: [Syntax]` (AST nodes to underline) + `notes: [Note]` (position + message)
- **`RuleViolation`**: `highlights: [HighlightRange]` (line/column ranges) + `notes: [Note]` (line/column + message)
- **`Diagnostic`** (JSON output): optional `highlights` and `notes` arrays, omitted when empty

Conversion helpers `resolvedHighlights(converter:)` and `resolvedNotes(converter:)` on `SyntaxViolation` translate AST positions to line/column via `SourceLocationConverter`.

Proof of concept on 2 rules:
- `RedundantObjcAttributeRule` — highlights the `@objc` attribute being removed
- `RedundantTypeAnnotationRule` — highlights the redundant type + note pointing to the initializer ("type is inferred from this initializer")
