---
# auh-okz
title: Split oversized test files (>1,000 lines)
status: ready
type: task
created_at: 2026-02-28T16:30:01Z
updated_at: 2026-02-28T16:30:01Z
parent: uac-wbq
---

Split the largest test files into logical sub-files. Target ~500 lines per file. Use existing comment section headers (e.g., `// indent parens`, `// indent braces`) as natural split points.

## Top Priority (>3,000 lines)
- `IndentTests.swift` (6,142) → split by comment sections into ~6-8 files
- `TokenizerTests.swift` (5,198) → split by token category
- `OrganizeDeclarationsTests.swift` (4,605)
- `RedundantSelfTests.swift` (4,322)
- `TrailingCommasTests.swift` (3,747)
- `ParsingHelpersTests.swift` (3,671)
- `WrapArgumentsTests.swift` (3,366)

## Medium Priority (1,000–3,000 lines)
- RedundantMemberwiseInitTests.swift (2,454)
- UnusedArgumentsTests.swift (1,593)
- RedundantReturnTests.swift (1,592)
- RedundantParensTests.swift (1,585)
- NoGuardInTestsTests.swift (1,458)
- SpaceAroundOperatorsTests.swift (1,208)
- CustomRulesTests.swift (1,175)
- SinglePropertyPerLineTests.swift (1,133)
- RedundantClosureTests.swift (1,094)
- ValidateTestCasesTests.swift (1,093)
- MarkTypesTests.swift (1,040)

## Naming Convention
`IndentTests.swift` → `IndentTests+Parens.swift`, `IndentTests+Braces.swift`, etc.
Each sub-file extends the original `@Suite` or defines a nested `@Suite`.

## Trade-off Note
These are vendored tests. Splitting increases future upstream sync burden. Focus on the worst offenders (>3k lines) first. Files between 500–1,000 can stay as-is.

## Verification
- `swift test` passes with no regressions
- No file exceeds ~800 lines
- Test count unchanged
