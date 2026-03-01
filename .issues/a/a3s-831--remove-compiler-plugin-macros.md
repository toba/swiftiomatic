---
# a3s-831
title: Remove compiler plugin macros
status: completed
type: task
priority: normal
created_at: 2026-02-28T01:28:58Z
updated_at: 2026-02-28T01:42:06Z
sync:
    github:
        issue_number: "19"
        synced_at: "2026-03-01T01:01:32Z"
---

Replace all macro usages (@AcceptableByConfigurationElement, @DisabledWithoutSourceKit, @AutoConfigParser, @SwiftSyntaxRule) with their expanded forms, then delete macro infrastructure.

## Phases
- [x] Phase 1: @AcceptableByConfigurationElement (18 files) — protocol extension
- [x] Phase 2: @DisabledWithoutSourceKit (10 files) — inline expansion
- [x] Phase 3: @AutoConfigParser (76 files) — generate apply() methods
- [x] Phase 4: @SwiftSyntaxRule (227 files) — explicit conformances + methods
- [x] Phase 5: Delete macro infrastructure (Package.swift, Macros.swift, Sources/Lint/Macros/)
- [x] Phase 6: Remove unused swift-syntax products (none needed)


## Summary of Changes

Replaced all 4 compiler plugin macros with their expanded forms:
- @AcceptableByConfigurationElement → protocol extension on RawRepresentable<String>
- @DisabledWithoutSourceKit → inline extension with static lazy postMessage
- @AutoConfigParser → generated typealias + apply(configuration:) method
- @SwiftSyntaxRule → explicit protocol conformances + makeVisitor/makeRewriter/preprocess methods

Deleted 8 macro source files, removed CompilerPluginSupport import, removed SwiftLintCoreMacros target from Package.swift. Build succeeds, all 12 tests pass.
