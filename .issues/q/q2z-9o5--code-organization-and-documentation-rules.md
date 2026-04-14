---
# q2z-9o5
title: Code organization and documentation rules
status: completed
type: feature
priority: normal
created_at: 2026-04-14T03:18:17Z
updated_at: 2026-04-14T17:32:59Z
parent: 77g-8mh
sync:
    github:
        issue_number: "289"
        synced_at: "2026-04-14T03:28:23Z"
---

Port code-organization, sorting, and documentation rules from SwiftFormat.

**Implementation**: Sorting rules are `SyntaxFormatRule` (format scope). `organizeDeclarations` is complex — start with `.suggest` scope. File header rules operate on trivia of the first token. Doc-comment rules extend or complement existing rules.

## Rules

- [x] `docComments` — Moved to blocked (c7r-77o) — Use doc comments (`///`) for API declarations, regular comments for internal code *(extend existing `UseTripleSlashForDocumentationComments` which only converts `/** */` → `///`)*
- [x] `docCommentsBeforeModifiers` — Place doc comments before any declaration modifiers or attributes (not between them)
- [x] `duplicateImports` — Already handled by `OrderedImports` rule (line 296-319)
- [x] `fileHeader` — Moved to blocked (c7r-77o) — Enforce a configured source file header template
- [x] `headerFileName` — Moved to blocked (c7r-77o) — Ensure file name in header comment matches actual file name
- [x] `markTypes` — Moved to blocked (c7r-77o) — Add `// MARK: -` comment before top-level types and extensions
- [x] `organizeDeclarations` — Moved to blocked (c7r-77o) — Organize members within type bodies by category (properties, init, methods, etc.)
- [x] `sortDeclarations` — Sort declarations between `// swiftiomatic:sort:begin` / `end` markers
- [x] `sortSwitchCases` — Sort switch cases alphabetically
- [x] `sortTypealiases` — Sort protocol composition typealiases alphabetically
- [x] `todos` — Enforce correct formatting for `TODO:`, `MARK:`, `FIXME:` comments (colon + space)


## Summary of Changes

Implemented 5 format rules with 63 tests:
- `Todos` (24 tests) — correct TODO/MARK/FIXME comment formatting
- `SortSwitchCases` (13 tests, opt-in) — sort comma-separated case items alphabetically
- `SortTypealiases` (13 tests) — sort protocol composition typealiases, remove duplicates
- `DocCommentsBeforeModifiers` (7 tests) — move doc comments before attributes/modifiers
- `SortDeclarations` (6 tests) — sort declarations between begin/end markers

Also resolved `duplicateImports` (already covered by `OrderedImports`). Moved 5 complex rules to blocked (c7r-77o): `docComments`, `fileHeader`, `headerFileName`, `markTypes`, `organizeDeclarations`.
