---
# q2z-9o5
title: Code organization and documentation rules
status: ready
type: feature
priority: normal
created_at: 2026-04-14T03:18:17Z
updated_at: 2026-04-14T03:18:17Z
parent: 77g-8mh
sync:
    github:
        issue_number: "289"
        synced_at: "2026-04-14T03:28:23Z"
---

Port code-organization, sorting, and documentation rules from SwiftFormat.

**Implementation**: Sorting rules are `SyntaxFormatRule` (format scope). `organizeDeclarations` is complex — start with `.suggest` scope. File header rules operate on trivia of the first token. Doc-comment rules extend or complement existing rules.

## Rules

- [ ] `docComments` — Use doc comments (`///`) for API declarations, regular comments for internal code *(extend existing `UseTripleSlashForDocumentationComments` which only converts `/** */` → `///`)*
- [ ] `docCommentsBeforeModifiers` — Place doc comments before any declaration modifiers or attributes (not between them)
- [ ] `duplicateImports` — Remove duplicate import statements
- [ ] `fileHeader` — Enforce a configured source file header template
- [ ] `headerFileName` — Ensure file name in header comment matches actual file name
- [ ] `markTypes` — Add `// MARK: -` comment before top-level types and extensions
- [ ] `organizeDeclarations` — Organize members within type bodies by category (properties, init, methods, etc.)
- [ ] `sortDeclarations` — Sort declarations between `// swiftiomatic:sort:begin` / `end` markers
- [ ] `sortSwitchCases` — Sort switch cases alphabetically
- [ ] `sortTypealiases` — Sort protocol composition typealiases alphabetically
- [ ] `todos` — Enforce correct formatting for `TODO:`, `MARK:`, `FIXME:` comments (colon + space)
