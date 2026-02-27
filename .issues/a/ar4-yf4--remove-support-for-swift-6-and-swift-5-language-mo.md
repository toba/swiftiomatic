---
# ar4-yf4
title: Remove support for Swift < 6 and Swift 5 language mode
status: in-progress
type: task
priority: normal
created_at: 2026-02-27T23:33:59Z
updated_at: 2026-02-27T23:34:43Z
---

Swiftiomatic targets Swift 6.2 with strict concurrency. Several vendored targets (SourceKitService, all Lint targets) still use `.swiftLanguageMode(.v5)` for compatibility with upstream code that isn't Swift 6 ready. Additionally, SwiftFormat rules may contain Swift 5 codepaths or version checks.

## Tasks

- [ ] Audit all targets using `.swiftLanguageMode(.v5)` in Package.swift
- [ ] Migrate SourceKitService to Swift 6 language mode (fix concurrency issues in SourceKittenFramework usage)
- [ ] Migrate vendored SwiftLint targets to Swift 6 language mode (Core, BuiltInRules, Framework, Macros, ExtraRules)
- [ ] Remove any Swift version checks / codepaths that handle Swift < 6
- [ ] Remove any `@preconcurrency import` annotations that are no longer needed after migration
- [ ] Verify all targets build cleanly with `.swiftLanguageMode(.v6)` and strict concurrency
