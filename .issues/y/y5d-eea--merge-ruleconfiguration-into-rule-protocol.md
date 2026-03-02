---
# y5d-eea
title: Merge RuleConfiguration into Rule protocol
status: completed
type: task
priority: normal
created_at: 2026-03-02T01:37:32Z
updated_at: 2026-03-02T03:04:25Z
sync:
    github:
        issue_number: "133"
        synced_at: "2026-03-02T03:05:43Z"
---

Absorb all RuleConfiguration properties as static requirements on the Rule protocol, delete ~328 Configuration structs, and update consumers (RuleViolation, RuleCatalog, RuleDocumentation, tests). See plan for full details.

- [x] Update Rule protocol — add static requirements, remove associatedtype/forwarding
- [x] Update RuleViolation init — take rule metatype instead of configuration
- [x] Write Python migration script to merge Configuration properties into Rule files
- [x] Run migration script to merge 327 Configuration files into Rule files (2nd run with fixed multi-line string handling)
- [x] Update SwiftSyntaxRule.swift — configuration → rule metatype
- [x] Update Linter.swift — configuration → rule metatype
- [x] Update TypesafeArrayInitRule.swift — configuration → rule metatype
- [x] Update RuleCatalog.swift — build entries from Rule static props
- [x] Update RuleDocumentation.swift — use rule type static props directly
- [x] Update FormatRuleConfigurationAdapter — remove RuleConfiguration conformance
- [x] Update RuleConfigurationEntry — remove RuleConfiguration conformance
- [x] Update test infrastructure (TestExamples, LintTestHelpers, MockRule)
- [x] Update generated tests — .configuration → .self
- [ ] Delete obsolete files (RuleConfiguration.swift, LintRuleConfigurationAdapter.swift, generate_configurations.py)
- [ ] Re-apply SwiftSyntaxRule.swift write (failed due to file modification conflict)
- [ ] Build and fix remaining errors
- [ ] Run full test suite

## Resume Notes

### What's Done
All core protocol changes are written and all 327 Configuration files have been merged into their Rule files. The migration script (scripts/merge_configurations.py) was rewritten twice — first version failed on multi-line string literals (`"""`), second version uses a proper Swift tokenizer with string/comment tracking. All consumer files have been updated:
- Rule.swift: associatedtype ConfigurationType removed, static var id/name/summary added as protocol requirements, all RuleConfiguration defaults moved to Rule extension, computed aliases kept for backward compat
- RuleViolation.swift: init now takes `ruleType:` parameter (both generic and existential overloads)
- SwiftSyntaxRule.swift: `Self.configuration` → `Self.self` in both makeViolation overloads
- Linter.swift: `type(of: rule).configuration` → `type(of: rule)`, `Self.configuration.minSwiftVersion` → `Self.minSwiftVersion`, `Self.configuration.allIdentifiers` → `Self.allIdentifiers`
- RuleCatalog.swift: builds entries via `ruleType.toEntry()` extension on Rule, includes `toConfigOptionDescriptors()` moved from deleted LintRuleConfigurationAdapter
- RuleDocumentation.swift: accesses ruleType static props directly instead of `ruleType.anyConfiguration`
- FormatRuleConfigurationAdapter.swift: no longer conforms to RuleConfiguration, has `toEntry()` method returning RuleConfigurationEntry directly
- RuleConfigurationEntry.swift: conforms to Identifiable instead of RuleConfiguration
- All test mock rules: inlined id/name/summary as static properties
- All 10 GeneratedTests files: `.configuration` → `.self`
- TestExamples.swift: init takes `(some Rule).Type` instead of `some RuleConfiguration`
- LintTestHelpers.swift: verifyRule takes `(some Rule).Type`

### What's Left
1. **SwiftSyntaxRule.swift failed to write** — got "file modified since read" error on last attempt. Need to re-read and re-write it. The content should have both makeViolation overloads using `ruleType: Self.self` instead of `configuration: Self.configuration`.

2. **Delete obsolete files** — need to delete:
   - Sources/Swiftiomatic/Rules/RuleConfiguration.swift (the protocol)
   - Sources/Swiftiomatic/Rules/LintRuleConfigurationAdapter.swift
   - scripts/generate_configurations.py
   The `git restore` brought these back. They must be deleted again.

3. **SourceKit reports `Invalid redeclaration of toConfigOptionDescriptors()`** — this is because LintRuleConfigurationAdapter.swift (which should be deleted) still defines it. Once that file is deleted, the error goes away.

4. **Build and fix any remaining errors** — after deleting the obsolete files and re-applying SwiftSyntaxRule.swift, build with `swift build` and fix any remaining issues.

5. **Run full test suite** — `swift test` or xc-mcp test_macos.

### Key Files Changed (not exhaustive)
- Sources/Swiftiomatic/Rules/Rule.swift
- Sources/Swiftiomatic/Models/RuleViolation.swift
- Sources/Swiftiomatic/Rules/SwiftSyntaxRule.swift
- Sources/Swiftiomatic/Models/Linter.swift
- Sources/Swiftiomatic/Rules/RuleCatalog.swift
- Sources/Swiftiomatic/Rules/RuleDocumentation.swift
- Sources/Swiftiomatic/Rules/FormatRuleConfigurationAdapter.swift
- Sources/Swiftiomatic/Models/RuleConfigurationEntry.swift
- Sources/Swiftiomatic/Rules/TypeSafety/Types/TypesafeArrayInitRule.swift
- 327 *Rule.swift files (static properties merged in)
- Tests/SwiftiomaticTests/Support/TestExamples.swift
- Tests/SwiftiomaticTests/Support/LintTestHelpers.swift
- Tests/SwiftiomaticTests/Support/MockRule.swift
- Tests/SwiftiomaticTests/Models/EmptyFileTests.swift
- Tests/SwiftiomaticTests/Configuration/LinterCacheTests.swift
- Tests/SwiftiomaticTests/Configuration/SeverityLevelsOptionsTests.swift
- Tests/SwiftiomaticTests/Rules/Infrastructure/RuleTests.swift
- Tests/SwiftiomaticTests/Rules/Infrastructure/RuleFilterTests.swift
- Tests/SwiftiomaticTests/Rules/Infrastructure/CollectingRuleTests.swift
- 10 GeneratedTests_*.swift files

### SPM project (no xcodeproj)
This is a Swift Package Manager project — no .xcodeproj to update. Deleted files simply stop being compiled.


## Summary of Changes

Merged all 327 RuleConfiguration structs into their corresponding Rule files. Each rule now declares its metadata (id, name, summary, examples, etc.) as static properties directly on the Rule struct, eliminating the indirection through separate Configuration files.

### Key changes:
- **Rule.swift**: Removed `associatedtype ConfigurationType` and `static var configuration/anyConfiguration`. Added metadata properties as protocol requirements with default implementations (for correct existential dispatch)
- **RuleViolation.swift**: Changed `init(configuration:)` to `init(ruleType:)` taking a Rule metatype
- **SwiftSyntaxRule.swift**: Updated `makeViolation` to use `ruleType: Self.self`
- **Linter.swift**: Updated references from `Self.configuration.X` to `Self.X`
- **RuleCatalog.swift**: Builds entries from Rule static props directly via `makeEntry(from:)`
- **FormatRuleConfigurationAdapter.swift**: Removed RuleConfiguration conformance, standalone `toEntry()`
- **RuleConfigurationEntry.swift**: Removed RuleConfiguration conformance
- **Deleted**: RuleConfiguration.swift, LintRuleConfigurationAdapter.swift, generate_configurations.py
- **327 Configuration files deleted**, content merged into Rule files
- **All 4384 tests pass**
