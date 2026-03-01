---
# c0i-g55
title: Remove legacy SwiftLint reporter system
status: completed
type: task
priority: normal
created_at: 2026-02-28T17:07:19Z
updated_at: 2026-02-28T17:15:50Z
sync:
    github:
        issue_number: "33"
        synced_at: "2026-03-01T01:01:37Z"
---

## Context

Swiftiomatic has two parallel output systems:

1. **`DiagnosticFormatter`** (19 lines, `Support/Models/DiagnosticFormatter.swift`) — used by the unified `Analyze` command. Has `formatXcode()` and `formatJSON()` covering all three output needs.
2. **`Reporters/`** (16 files, ~800 lines) + `ReportersList.swift` — the old SwiftLint reporter system with 15 CI-platform integrations (CSV, Checkstyle, CodeClimate, Emoji, GitHub Actions, GitLab JUnit, HTML, JUnit, Markdown, RelativePath, SARIF, SonarQube, Summary, Xcode, JSON).

The reporter system is only referenced from `LintOrAnalyzeCommand.swift` (legacy lint orchestration, slated for removal). Zero tests reference reporters. `DiagnosticFormatter` already covers:

- **Xcode inline diagnostics**: `formatXcode()` → `file:line:column: severity: [ruleID] message`
- **Agent consumption**: `formatJSON()` → Codable Diagnostic array
- **Human text**: `formatXcode()` output is readable as-is

## Checklist

- [x] Delete `Sources/Swiftiomatic/Reporters/` directory (16 files)
  - Reporter.swift (protocol + reporterFrom function)
  - CSVReporter.swift
  - CheckstyleReporter.swift
  - CodeClimateReporter.swift
  - EmojiReporter.swift
  - GitHubActionsLoggingReporter.swift
  - GitLabJUnitReporter.swift
  - HTMLReporter.swift
  - JSONReporter.swift
  - JUnitReporter.swift
  - MarkdownReporter.swift
  - RelativePathReporter.swift
  - SARIFReporter.swift
  - SonarQubeReporter.swift
  - SummaryReporter.swift
  - XcodeReporter.swift
- [x] Delete `Sources/Swiftiomatic/Models/ReportersList.swift`
- [x] Remove reporter references from `LintOrAnalyzeCommand.swift`
- [x] Remove reporter property from Configuration types
- [x] Remove helper extensions only used by reporters (escapedForCSV, escapedForMarkdown, sha256, escapedForXML, etc.)
- [x] Verify build succeeds
- [x] Verify tests pass

## Summary of Changes

Removed the entire legacy SwiftLint reporter system (16 reporter files, ReportersList.swift, String+XML extension) and all references from LintOrAnalyzeCommand and Configuration. DiagnosticFormatter covers all output needs.
