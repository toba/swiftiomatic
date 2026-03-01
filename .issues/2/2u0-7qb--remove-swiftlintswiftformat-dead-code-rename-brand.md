---
# 2u0-7qb
title: Remove SwiftLint/SwiftFormat dead code & rename branding
status: completed
type: task
priority: normal
created_at: 2026-02-28T23:16:57Z
updated_at: 2026-02-28T23:39:41Z
sync:
    github:
        issue_number: "28"
        synced_at: "2026-03-01T01:01:33Z"
---

## Tasks

- [x] Phase 1a: Remove unused Configuration properties (warningThreshold, allowZeroLintableFiles, strict, lenient, baseline, writeBaseline, checkForUpdates)
- [x] Phase 1b: Remove pinnedVersion + rename LintVersion → SwiftiomaticVersion
- [x] Phase 1c: Remove multi-config init pathway (init(configurationFiles:), resultingConfiguration, makeIncludedAndExcludedPaths, merged(withChild:))
- [x] Phase 1d: Remove RulesWrapper.merged(with:) and fix test helper
- [x] Phase 1e: Delete Baseline.swift and remove Issue references
- [x] Phase 2a: Cache path branding
- [x] Phase 2b: Environment variable rename
- [x] Phase 2c: FileHeader placeholder rename
- [x] Phase 2d: Doc comment branding
- [x] Phase 3a: Remove Swift 5.x constants
- [x] Phase 3b: Change default minSwiftVersion
- [x] Phase 3c: Remove redundant minSwiftVersion from rules
- [x] Phase 3d: Remove dead Swift 5.x version checks
- [x] Phase 4: Type & folder renames (RulesWrapper→RuleSelection, ConfigurationRuleWrapper→ConfiguredRule)
- [x] Verification: build, test, grep checks


## Summary of Changes

### Phase 1: Removed dead Configuration properties & multi-config code
- Removed 7 unused Configuration properties: warningThreshold, allowZeroLintableFiles, strict, lenient, baseline, writeBaseline, checkForUpdates
- Removed pinnedVersion parameter and exit(2) version check
- Renamed LintVersion → SwiftiomaticVersion (version 1.0.0)
- Replaced init(configurationFiles:) multi-config pathway with simpler init(configurationFile:) single-file init
- Removed resultingConfiguration(), makeIncludedAndExcludedPaths(), merged(withChild:) from Configuration.swift
- Removed RulesWrapper.merged(with:) and all its private merge helpers
- Deleted Baseline.swift and removed baselineNotReadable from Issue.swift
- Fixed test helpers to construct Configuration directly instead of merging

### Phase 2: Renamed SwiftLint branding
- Cache path: SwiftLint → Swiftiomatic, LintVersion → SwiftiomaticVersion
- Env vars: SWIFTLINT_SWIFT_VERSION → SWIFTIOMATIC_SWIFT_VERSION, SWIFTLINT_LOG_MODULE_USAGE → SWIFTIOMATIC_LOG_MODULE_USAGE
- FileHeader: SWIFTLINT_CURRENT_FILENAME → CURRENT_FILENAME, isSwiftLintCommand → isSmDirective
- Updated doc comments across 14+ files (SwiftLint → Swiftiomatic/sm)
- Only GitHub URL references preserved (provenance)

### Phase 3: Simplified Swift version checks
- Removed all Swift 5.x version constants (.five through .fiveDotNine)
- Changed default minSwiftVersion from .five to .six
- Removed minSwiftVersion from 11 rules (all ≤ 6.0)
- Simplified RedundantSelfRule: removed always-true .fiveDotThree/.fiveDotEight checks
- Simplified UnusedImportRule: removed always-true .fiveDotSix guard

### Phase 4: Type & folder renames
- RulesWrapper → RuleSelection (type + file)
- ConfigurationRuleWrapper → ConfiguredRule (typealias)
- configurationRuleWrapper property → configuredRule

### Verification
- swift build: clean (warnings only, all pre-existing)
- swift test: 2 pre-existing failures only (SourceKit-dependent tests)
- grep SwiftLint in Sources: only GitHub URL references remain
- grep LintVersion, Baseline, ConfigurationRuleWrapper, RulesWrapper: zero hits
