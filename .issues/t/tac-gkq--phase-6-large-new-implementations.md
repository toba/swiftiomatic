---
# tac-gkq
title: 'Phase 6: Large new implementations'
status: ready
type: task
priority: normal
created_at: 2026-04-14T18:37:12Z
updated_at: 2026-04-14T18:37:12Z
parent: c7r-77o
sync:
    github:
        issue_number: "301"
        synced_at: "2026-04-14T18:45:53Z"
---

Substantial rules not yet ported.

- [ ] `propertyTypes` — Configure inferred vs explicit property types. 325-line SwiftFormat impl, 3 config modes, bidirectional conversion. Parent: ka6-zh3.
- [ ] `trailingClosures` — Use trailing closure syntax. 187-line SwiftFormat impl, multiple trailing closure handling. Parent: ka6-zh3.
- [ ] `unusedArguments` — Mark unused function arguments with `_`. 401-line SwiftFormat impl, scope analysis. Parent: ka6-zh3.
- [ ] `unusedPrivateDeclarations` — Remove unused private declarations. Whole-file analysis, high false-positive risk. Parent: ka6-zh3.
- [ ] `urlMacro` — Replace `URL(string:)!` with `#URL(_:)`. Requires config + import management. Parent: ka6-zh3.
- [ ] `docComments` — Convert `//` to `///` before API declarations. 300+ line impl. Parent: q2z-9o5.
- [ ] `fileHeader` — Enforce file header template. Requires config + file path. Parent: q2z-9o5.
- [ ] `headerFileName` — Ensure header file name matches actual file. Parent: q2z-9o5.
- [ ] `markTypes` — Add `// MARK: -` before types. 400+ line impl. Parent: q2z-9o5.
- [ ] `organizeDeclarations` — Organize members by category. 600+ line impl. Parent: q2z-9o5.
