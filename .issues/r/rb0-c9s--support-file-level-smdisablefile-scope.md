---
# rb0-c9s
title: Support file-level `sm:disable:file` scope
status: completed
type: feature
priority: normal
created_at: 2026-04-11T17:53:01Z
updated_at: 2026-04-11T18:16:35Z
sync:
    github:
        issue_number: "180"
        synced_at: "2026-04-11T18:44:01Z"
---

Add a file-level scope to the `sm:disable` directive system.

Currently supported scopes: `:previous`, `:this`, `:next`, and bare (disable until `sm:enable`).

A file-level scope like `// sm:disable:file rule_id` at the top of a file would disable a rule for the entire file without needing a matching `sm:enable`.

Upstream reference: swiftlang/swift-format 602.0.0 added file-level ignore directives for specific rules.

## Plan

- [x] Add `case file` to `Command.Modifier` enum
- [x] Handle `.file` in `expand()` — single disable from line 0 to EOF
- [x] Add parsing tests for `sm:disable:file` / `sm:enable:file`
- [x] Add expansion tests
- [x] Add region tests
- [x] Add integration tests (violation suppression)
- [x] Add superfluous disable command tests


## Summary of Changes

Added `sm:disable:file` / `sm:enable:file` directive scope. The `:file` modifier expands to a single command at line 0, creating a region that covers the entire file regardless of where the directive appears in the source. No parser changes were needed — the existing `Modifier(rawValue:)` initializer picks up the new `file` case automatically.

### Files changed
- `Sources/SwiftiomaticKit/Models/Command.swift` — added `case file` to `Modifier` enum, added `.file` case to `expand()`
- `Tests/SwiftiomaticTests/Configuration/CommandTests.swift` — parsing, expansion, and superfluous disable tests
- `Tests/SwiftiomaticTests/Rules/Infrastructure/RegionTests.swift` — region building tests
- `Tests/SwiftiomaticTests/Rules/Infrastructure/DisableAllTests.swift` — integration tests for violation suppression
