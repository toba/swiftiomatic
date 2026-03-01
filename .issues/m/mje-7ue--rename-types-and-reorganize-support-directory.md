---
# mje-7ue
title: Rename types and reorganize Support/ directory
status: completed
type: task
priority: normal
created_at: 2026-02-28T20:31:39Z
updated_at: 2026-02-28T20:31:39Z
sync:
    github:
        issue_number: "55"
        synced_at: "2026-03-01T01:01:39Z"
---

## Type Renames
- [x] `HashableConfigurationRuleWrapperWrapper` → `RuleIdentityWrapper` (+ file)
- [x] `AnyTypeHelpers` → `AnyTypeClassifier` (+ file)
- [x] `ConcurrencyDetectionHelpers` → `ConcurrencyPatternDetector` (+ file)
- [x] `TaskDetectionHelpers` → `TaskPatternDetector` (+ file)
- [x] `SwiftUIContainerHelpers` → `SwiftUILayoutDetector` (+ file)
- [x] `NamingHelpers` → `NamingConventionChecker` (+ file)
- [x] `SwiftSyntaxKindBridge` → `SyntaxKindMapper` (+ file + test file)
- [x] `LintableFileManager` → `LintableFileDiscovering` (+ file)
- [x] `swiftlintConstructor` → `customConstructor` in YamlParser.swift
- [x] `LegacyFunctionVisitor+Rewriter.swift` → `LegacyFunctionRuleSupport.swift`

## Folder Reorganization
- [x] Create `Support/Detectors/` and move 7 detection helpers there
- [x] Flatten `Support/Rewriters/` into `Support/Visitors/`
- [x] Update all references across Sources/ and Tests/

## Summary of Changes
All type renames applied, all references updated (verified via grep sweep), directory restructured with Detectors/ subfolder and Rewriters/ flattened.
