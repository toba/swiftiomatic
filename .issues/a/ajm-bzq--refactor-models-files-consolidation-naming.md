---
# ajm-bzq
title: 'Refactor Models/ files: consolidation & naming'
status: completed
type: task
priority: normal
created_at: 2026-02-28T19:29:02Z
updated_at: 2026-02-28T19:52:26Z
---

Findings from swift-review of `Sources/Swiftiomatic/Models/` (33 files). Complete the SwiftLint→Swiftiomatic migration by fixing naming, file mismatches, and doc strings.

## Work Items

### HIGH: Filename ↔ type mismatches
- [x] Rename `RuleViolation.swift` → `SyntaxViolation.swift` (type is `ReasonedRuleViolation`, rename to `SyntaxViolation`)
- [x] Rename `Version.swift` → `LintVersion.swift` (type inside is `LintVersion`)

### HIGH: Legacy "SwiftLint" prefixes on types
- [x] `SwiftLintSyntaxMap` → `ResolvedSyntaxMap` (file + type + all references — `SyntaxMap` collided with raw SourceKit type)
- [x] `SwiftLintSyntaxToken` → `ResolvedSyntaxToken` (file + type + all references — `SyntaxToken` collided with raw SourceKit type)

### MEDIUM: Misleading or vague type names
- [x] `StyleViolation` → `RuleViolation` — not just "style", covers lint/metrics/perf/concurrency (~265 references, mechanical rename)
- [x] `ReasonedRuleViolation` → `SyntaxViolation` — produced by `ViolationsSyntaxVisitor`, "Reasoned" adds nothing
- [x] `SwiftExpressionKind` → `ExpressionKind` — "Swift" redundant inside Swift analysis module (~15 files)
- [x] Inline `ConfigurationRuleWrapper` typealias (1-line file) into `RuleList.swift`

### MEDIUM: Doc strings still reference "SwiftLint"
- [x] `StyleViolation.swift:3` — "considered invalid by a SwiftLint rule" → "considered invalid by a rule"
- [x] `SourceKitDictionary.swift:2` — "SwiftLint-specific values" → "analysis-specific values"
- [x] `SwiftLintSyntaxToken.swift:2` — "A SwiftLint-aware Swift syntax token" → update after rename
- [x] `SwiftLintSyntaxMap.swift:7` — update after rename
- [x] `LinterCache.swift:50-51` — "SwiftLint configuration" (2x) → "configuration"
- [x] `RuleList.swift:7` — "A list of available SwiftLint rules" → "A list of available rules"
- [x] `RuleStorage.swift:22` — "The SwiftLint rule" → "The rule"
- [x] `Issue.swift:104` — "SwiftLintError.genericWarning" → "Issue.genericWarning"

### LOW: Minor naming improvements
- [x] ~~Consider renaming `LintVersion`~~ — skip: name is already clear, alternatives are misleading or verbose
- [x] ~~Consider renaming `Correction`~~ — skip: well-documented, low usage, `CorrectionResult` could be confused with Result type

### LOW: Sendable conformance
- [x] ~~Add `Sendable` to `SourceKitDictionary`~~ — already implicit: struct with all `let` Sendable properties in Swift 6 mode

### NOT FIXING (intentional patterns)
- `RuleStorage.data: [ObjectIdentifier: [SwiftSource: Any]]` — standard type-erasure for heterogeneous CollectingRule.FileInfo
- `RuleList.allRulesWrapped(configurationDict: [String: Any])` — YAML parsing boundary, acceptable
- `LinterCache.save() throws` — heterogeneous error types, typed throws not worth a wrapper enum
- `nonisolated(unsafe) static var printDeprecationWarnings` — acceptable until made a config-time constant
- `@unchecked Sendable` on Linter/CollectedLinter — necessary while `any Rule` isn't Sendable

## Recommended execution order
1. `SwiftLintSyntaxMap`/`SwiftLintSyntaxToken` renames (isolated, few refs)
2. `ReasonedRuleViolation` → `SyntaxViolation` + file rename
3. `StyleViolation` → `RuleViolation` (widest impact)
4. `SwiftExpressionKind` → `ExpressionKind`
5. Doc string cleanup
6. Remaining file renames and inlining

Pipeline after renames:
```
SyntaxViolation → RuleViolation → Diagnostic
(position-level   (resolved with    (unified output
 from visitors)    location/rule)    for all engines)
```


## Summary of Changes

Renamed 6 types, 7 files, cleaned up all "SwiftLint" doc strings in Models/, and inlined `ConfigurationRuleWrapper` typealias.

### Type renames
- `SwiftLintSyntaxMap` → `ResolvedSyntaxMap` (not `SyntaxMap` — collides with raw SourceKit type)
- `SwiftLintSyntaxToken` → `ResolvedSyntaxToken` (same collision reason)
- `ReasonedRuleViolation` → `SyntaxViolation`
- `StyleViolation` → `RuleViolation` (also renamed `styleViolations` → `ruleViolations` methods)
- `SwiftExpressionKind` → `ExpressionKind`

### File renames
- `SwiftLintSyntaxMap.swift` → `ResolvedSyntaxMap.swift`
- `SwiftLintSyntaxToken.swift` → `ResolvedSyntaxToken.swift`
- `RuleViolation.swift` → `SyntaxViolation.swift`
- `StyleViolation.swift` → `RuleViolation.swift`
- `SwiftExpressionKind.swift` → `ExpressionKind.swift`
- `Version.swift` → `LintVersion.swift`
- `ConfigurationRuleWrapper.swift` → deleted (inlined into `RuleList.swift`)

### Doc strings
Removed all "SwiftLint" references from Models/ doc strings (8 files, 14 occurrences).

### Additional doc cleanup beyond Models/
- `Correction.swift`, `Region.swift`, `ViolationSeverity.swift`, `RuleDescription.swift`, `Linter.swift` — all cleaned.

### Needs build verification by other agent.
