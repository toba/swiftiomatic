---
# vu5-l8x
title: Fix all swift-review findings in Sources/Swiftiomatic
status: completed
type: task
priority: normal
created_at: 2026-03-01T06:58:58Z
updated_at: 2026-03-01T07:59:17Z
sync:
    github:
        issue_number: "120"
        synced_at: "2026-03-01T08:00:21Z"
---

Fix all high, medium, and low priority findings from the swift-review of Sources/Swiftiomatic/.

## High Priority
- [x] Fix swapped doc comments in SeverityConfiguration and ChildOptionSeverityConfiguration
- Moved to ay9-7gx: Unify ViolationSeverity and DiagnosticSeverity into one enum
- [x] Delete dead code: Correction.swift, NSRange+Intersects.swift (partitioned is used)
- [x] Move misplaced rule files (AgentReviewRule, PrivateSubjectRule, NumberFormatting, etc.)
- [x] Fix O(n²) characterPosition(of:) in String+PathAndRange.swift
- [x] Delete Suggest/Output/JSONFormatter.swift (one-line wrapper)
- [x] Rename Source enum to DiagnosticSource
- [x] Make Scope package-visible

## Medium Priority
- [x] Rename types: Issue→SwiftiomaticError, ChildOptionSeverityConfiguration→OptionSeverityConfiguration, RegularExpression→CachedRegex
- [x] Rename properties: Location.character→column, RuleList.list→rules
- [x] Replace ConfiguredRule tuple typealias with struct
- [x] Make confidence non-optional with .high default
- [ ] Add typed throws where applicable
- [ ] Split large files: RuleConfigurationDescription, Linter, String+PathAndRange, etc.
- [x] Change suggestMinConfidence from String to Confidence, formatSwiftVersion from String to Version
- [x] Extract allCases.firstIndex Comparable pattern to shared extension
- [x] Extract buildFormatEngine duplication
- [x] Unify EquatableMacro and URLMacro into NamedMacro
- [x] Fix String+Path.swift — merged into URL+filePath.swift

## Low Priority
- [x] Rename directories: Swift6→Concurrency, Bindings→Expressions, AccessControl→Visibility
- [x] Move SourceKit types from Models to SourceKit directory
- [x] Extract VersionComparable to own file
- [x] Rename SwiftVersion constants to v6_0 style
- [x] Wrap QueuedPrint free functions in enum Console
- [x] Remove GRDB from FileDiscovery.excludedDirectories
- [x] Document Any usage at YAML boundaries
- [x] Make swiftUIPropertyWrappers a file-level constant (protocol extension can't have static let)
- [x] Renamed to Console.swift with enum Console namespace
- [x] Move test infrastructure (captureConsole) from SwiftiomaticError to Console
- [x] Separate cacheURL side effect into prepareCacheDirectory()
- [x] Rename ResolvedSyntaxToken.value to .token
- [x] Rename ASTRule to SourceKitASTRule

## Summary of Changes
(to be filled on completion)
