---
# hrt-4b9
title: Rename and restructure 58 *RuleExamples.swift files to *Rule+examples.swift with extension pattern
status: completed
type: task
priority: normal
created_at: 2026-03-02T20:57:28Z
updated_at: 2026-03-02T21:08:23Z
sync:
    github:
        issue_number: "134"
        synced_at: "2026-03-02T21:31:17Z"
---

Migrate example files from standalone enum pattern to extension pattern:

## Current (old)
`[Name]RuleExamples.swift` with `enum [Name]RuleExamples { static let ... }`

## Target (new) 
`[Name]Rule+examples.swift` with `extension [Name]Rule { static var ... }`

## Steps
- [x] Process all 58 *RuleExamples.swift files
- [x] Rename files (git mv)
- [x] Change enum → extension (kept static let)
- [x] Remove bridging code from rule files
- [x] Build to verify
- [x] Run tests to verify (4383 passed)

## Files
58 files matching `Sources/Swiftiomatic/Rules/**/*RuleExamples.swift`
Plus 2 already-renamed but not restructured: UnneededSynthesizedInitializerRule+examples.swift, UnneededThrowsRule+examples.swift


## Summary of Changes

- Renamed 58 `*RuleExamples.swift` files to `*Rule+examples.swift` via git mv
- Changed `enum FooRuleExamples` → `extension FooRule` in all 60 files (58 renamed + 2 already renamed)
- Removed bridging properties from 60 rule files that forwarded to the old enums
- Fixed 5 test files referencing old enum names
- Fixed `LegacyConstantRule` referencing `LegacyConstantRuleExamples.patterns` → `LegacyConstantRule.patterns`
- Removed `// sm:disable:next type_name` comments (no longer needed for extensions)
- Fixed `SeverityConfiguration` → `SeverityOption` rename across 104 files (Xcode rename had missed them)
- Build succeeds, all 4383 tests pass
