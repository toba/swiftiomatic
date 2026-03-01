---
# ay9-7gx
title: Unify ViolationSeverity and DiagnosticSeverity into one enum
status: completed
type: task
priority: normal
created_at: 2026-03-01T07:58:51Z
updated_at: 2026-03-01T18:37:30Z
sync:
    github:
        issue_number: "122"
        synced_at: "2026-03-01T21:06:26Z"
---

These two severity enums serve overlapping purposes but are deeply entangled throughout the codebase. Unifying them requires careful migration of all call sites.

Deferred from vu5-l8x because of the scope of changes required.



## Summary of Changes

Unified `ViolationSeverity` (package, internal) and `DiagnosticSeverity` (public, output) into a single `public enum Severity` with all necessary conformances.

- **Renamed** `ViolationSeverity.swift` → `Severity.swift` via `git mv` (preserves history)
- **Promoted** access level from `package` to `public`; added `public` to `<` operator (fixes missing `Comparable` impl bug on old `DiagnosticSeverity`)
- **Deleted** `DiagnosticSeverity` enum from `Diagnostic.swift`
- **Simplified** `RuleViolation.toDiagnostic()` — severity passes through directly instead of manual conversion
- **Renamed** `typealias Severity` in `NestingRule+Configuration` and `NameConfiguration` to avoid shadowing the new module-level `Severity` enum
- **Mechanical rename** across 20+ files in Sources/ and Tests/
