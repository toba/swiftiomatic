---
# y8r-1uz
title: Add diagnostic highlights and notes to RuleViolation
status: ready
type: feature
priority: normal
created_at: 2026-04-12T23:54:23Z
updated_at: 2026-04-12T23:54:23Z
parent: oad-n72
sync:
    github:
        issue_number: "252"
        synced_at: "2026-04-13T00:25:21Z"
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

- [ ] Add optional `highlights` field to `SyntaxViolation` or `RuleViolation`
- [ ] Add optional `notes` field with position + message pairs
- [ ] Propagate highlights/notes through `RuleViolation` → `Diagnostic` pipeline
- [ ] Update JSON output format to include highlights and notes
- [ ] Add highlights to 2-3 rules as proof of concept
