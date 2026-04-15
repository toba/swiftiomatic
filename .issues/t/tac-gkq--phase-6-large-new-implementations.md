---
# tac-gkq
title: 'Phase 6: Large new implementations'
status: completed
type: task
priority: normal
created_at: 2026-04-14T18:37:12Z
updated_at: 2026-04-15T00:13:13Z
parent: c7r-77o
sync:
    github:
        issue_number: "301"
        synced_at: "2026-04-15T00:34:46Z"
---

Substantial rules not yet ported.

- [x] `trailingClosures` — Use trailing closure syntax. 187-line SwiftFormat impl, multiple trailing closure handling. Parent: ka6-zh3.
- [x] `unusedArguments` — Mark unused function arguments with `_`. 401-line SwiftFormat impl, scope analysis. Parent: ka6-zh3.
- [x] `urlMacro` — Replace `URL(string:)!` with `#URL(_:)`. Requires config + import management. Parent: ka6-zh3.
- [x] `docComments` — Convert `//` to `///` before API declarations. 300+ line impl. Parent: q2z-9o5.
- [x] `fileHeader` — Enforce file header template. Requires config + file path. Parent: q2z-9o5.


## Summary of Changes

All 5 substantial rules ported from SwiftFormat as format rules with auto-fix:

- **trailingClosures** — Converts closure arguments to trailing closure syntax, handles single and multiple trailing closures
- **unusedArguments** — Marks unused function/init/subscript parameters, closure parameters, and for-loop variables with `_`; scope-aware shadowing detection (let/var, guard let, if let, closures, switch cases, nested functions)
- **urlMacro** — Replaces `URL(string:)!` with `#URL(_:)` macro, adds `import Foundation` when needed
- **docComments** — Converts `//` comments to `///` doc comments before API declarations
- **fileHeader** — Enforces file header template via configuration
