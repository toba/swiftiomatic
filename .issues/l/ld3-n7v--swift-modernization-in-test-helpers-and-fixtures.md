---
# ld3-n7v
title: Swift modernization in test helpers and fixtures
status: completed
type: task
priority: normal
created_at: 2026-02-28T16:30:01Z
updated_at: 2026-02-28T21:20:03Z
parent: uac-wbq
sync:
    github:
        issue_number: "70"
        synced_at: "2026-03-01T01:01:43Z"
---

Apply modern Swift idioms to test infrastructure and helpers.

## Items

- [x] Replace force unwraps with \`try #require\` in test code (e.g., \`data(using: .utf8)!\` in LintTestHelpers.swift:18)
- [x] Replace \`try!\` / \`as!\` with \`try #require\` / \`as?\` + \`#require\`
- [x] Use modern \`URL\` APIs (\`URL(filePath:)\` instead of \`URL(fileURLWithPath:)\`)
- [x] ~Replace \`Process\` usage in \`macOSSDKPath()\`~ — N/A, Process is the standard API
- [x] ~Audit temp file creation~ — N/A, single usage with UUID names in system temp

## Key Files
- \`Tests/SwiftiomaticTests/Support/LintTestHelpers.swift\` (703 lines)
- \`Tests/SwiftiomaticTests/Support/FormatTestHelper.swift\` (150 lines)
- Force unwraps scattered across ~15 test files

## Verification
- \`swift test\` passes with no regressions
- No remaining force unwraps in test support code
- No force unwraps in test methods (test fixtures/strings are fine)


## Summary of Changes

- Replaced `URL(fileURLWithPath:)` with `URL(filePath:)` across all test support files and 3 test suites
- Replaced `(as? Type)!` force casts with `try #require(... as? Type)` in YamlSwiftLintTests
- Replaced `SwiftSource(path:)!` force unwraps with `try #require(SwiftSource(path:))` in 6 test files
- Replaced `makeConfig(...)!` with `try #require(makeConfig(...))` in 4 BuiltInRules test files
- Replaced `contents.data(using: .utf8)!` with `Data(contents.utf8)` (non-optional)
- Replaced `file.path!` with guard-let pattern in assertCorrection
- Replaced `String(contentsOfFile:)` with `String(contentsOf: URL)` modern API
- Replaced `NSString` path manipulation with `URL(filePath:)` chains
