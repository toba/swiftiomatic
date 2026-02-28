---
# ld3-n7v
title: Swift modernization in test helpers and fixtures
status: ready
type: task
created_at: 2026-02-28T16:30:01Z
updated_at: 2026-02-28T16:30:01Z
parent: uac-wbq
---

Apply modern Swift idioms to test infrastructure and helpers.

## Items

- [ ] Replace force unwraps with \`try #require\` in test code (e.g., \`data(using: .utf8)!\` in LintTestHelpers.swift:18)
- [ ] Replace \`try!\` / \`as!\` with \`try #require\` / \`as?\` + \`#require\`
- [ ] Use modern \`URL\` APIs (\`URL(filePath:)\` instead of \`URL(fileURLWithPath:)\`)
- [ ] Replace \`Process\` usage in \`macOSSDKPath()\` with modern patterns if applicable
- [ ] Audit temp file creation for proper cleanup (consider \`TestScoping\` trait)

## Key Files
- \`Tests/SwiftiomaticTests/Support/LintTestHelpers.swift\` (703 lines)
- \`Tests/SwiftiomaticTests/Support/FormatTestHelper.swift\` (150 lines)
- Force unwraps scattered across ~15 test files

## Verification
- \`swift test\` passes with no regressions
- No remaining force unwraps in test support code
- No force unwraps in test methods (test fixtures/strings are fine)
