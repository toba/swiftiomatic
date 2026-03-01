---
# f01-1e6
title: 'Phase 2: Vendor SwiftLint source'
status: completed
type: task
priority: normal
created_at: 2026-02-27T23:05:22Z
updated_at: 2026-02-27T23:08:45Z
parent: 7ls-zus
sync:
    github:
        issue_number: "75"
        synced_at: "2026-03-01T01:01:43Z"
---

- [ ] Clone SwiftLint 0.63.2
- [ ] Copy SwiftLintCore into Sources/Lint/Core/
- [ ] Copy SwiftLintBuiltInRules into Sources/Lint/BuiltInRules/
- [ ] Strip CLI, plugins, test helpers, macros
- [ ] Add new dependencies to Package.swift
- [ ] Add Lint target with .swiftLanguageMode(.v5)
- [ ] Get swift build passing
