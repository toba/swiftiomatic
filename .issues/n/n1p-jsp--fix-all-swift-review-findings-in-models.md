---
# n1p-jsp
title: Fix all swift-review findings in Models/
status: completed
type: task
priority: normal
created_at: 2026-03-01T04:34:49Z
updated_at: 2026-03-01T04:42:14Z
sync:
    github:
        issue_number: "117"
        synced_at: "2026-03-01T04:54:08Z"
---

Fix all issues from swift-review of Sources/Swiftiomatic/Models/:

- [x] §1: Consolidate Example skip methods with WritableKeyPath helper
- [x] §2: Extract default init(fromAny:context:) for Self-castable types (DirectlyCastableConfigurationElement protocol)
- [x] §5: Replace nonisolated(unsafe) static var with Mutex<Bool> in Issue.swift
- [x] §6: Eliminate redundant rank/priority Comparable boilerplate (Confidence, DiagnosticSeverity, AccessControlLevel)
- [x] §7: Rename 6 Bool properties to read as assertions (shouldTest*, isExcludedFromDocumentation, isInline)
- [x] §7: Rename InlinableOptionType to InlinableOption
- [x] §8: Fix convenience_type lint warning (struct → enum for RuleConfigurationDescriptionBuilder)
- [x] §8: Fix typo in RuleStorage doc comment

## Summary of Changes

### Models/ direct edits
- **Confidence.swift**: Added CaseIterable, removed rank computed property
- **Diagnostic.swift**: Added CaseIterable to DiagnosticSeverity, removed rank computed property
- **AccessControlLevel.swift**: Added CaseIterable, replaced priority property with allCases.firstIndex comparison
- **Example.swift**: Renamed 5 Bool properties (shouldTest*, isExcludedFromDocumentation), added KeyPath-based setting() helper, consolidated 4 skip methods + focused()
- **Issue.swift**: Replaced nonisolated(unsafe) static var with Mutex<Bool> backed property
- **RuleConfigurationDescription.swift**: struct→enum for builder, InlinableOptionType→InlinableOption, inline→isInline, extracted DirectlyCastableConfigurationElement protocol for Bool/String/Int init(fromAny:)
- **RuleStorage.swift**: Fixed trailing '.s' typo in doc comment

### Mass renames across ~70 files
- excludeFromDocumentation → isExcludedFromDocumentation
- testMultiByteOffsets → shouldTestMultiByteOffsets
- testWrappingInComment → shouldTestWrappingInComment
- testWrappingInString → shouldTestWrappingInString
- testDisableCommand → shouldTestDisableCommand
- InlinableOptionType → InlinableOption
- @ConfigurationElement(inline: true) → @ConfigurationElement(isInline: true)
