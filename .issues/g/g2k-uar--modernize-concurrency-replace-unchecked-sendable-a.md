---
# g2k-uar
title: 'Modernize concurrency: replace @unchecked Sendable and DispatchQueue'
status: completed
type: task
priority: normal
created_at: 2026-04-14T02:42:22Z
updated_at: 2026-04-14T03:01:32Z
parent: kqx-iku
sync:
    github:
        issue_number: "274"
        synced_at: "2026-04-14T03:02:34Z"
---

## @unchecked Sendable (4 occurrences)
Frontend classes use `@unchecked Sendable` with DispatchQueue for synchronization. Evaluate whether `Mutex` can replace the queue, enabling proper Sendable conformance.

- `Sources/sm/Frontend/Frontend.swift:18` — `class Frontend: @unchecked Sendable`
- `Sources/sm/Frontend/Frontend.swift:133` — `class FileToProcess: @unchecked Sendable`
- `Sources/sm/Frontend/LintFrontend.swift:19` — `class LintFrontend: Frontend, @unchecked Sendable`
- `Sources/sm/Frontend/FormatFrontend.swift:19` — `class FormatFrontend: Frontend, @unchecked Sendable`

## DispatchQueue → Mutex candidate
- `Sources/sm/Utilities/StderrDiagnosticPrinter.swift:42` — serial queue for thread-safe output → `Mutex`

## nonisolated(unsafe) on metatype (SE-0470)
- `Sources/Swiftiomatic/Core/RuleBasedFindingCategory.swift:21` — `nonisolated(unsafe) let ruleType: Rule.Type`
  Since `Rule` conforms to `Sendable`, the metatype is already Sendable (SE-0470). The `nonisolated(unsafe)` may be removable.

## Tasks
- [x] Evaluate Frontend classes for Mutex conversion (skipped — deep mutable state across DispatchQueue.concurrentPerform makes this invasive and risky)
- [x] Convert StderrDiagnosticPrinter DispatchQueue to Mutex
- [x] Check if RuleBasedFindingCategory nonisolated(unsafe) is still needed (SE-0470) — still needed, Rule protocol doesn't conform to Sendable
- [x] Build and test


## Summary of Changes

- Replaced `DispatchQueue.sync` in `StderrDiagnosticPrinter` with `Mutex`; also made the class properly `Sendable`
- Frontend `@unchecked Sendable` left as-is — the class hierarchy has mutable `DiagnosticsEngine`, `ConfigurationProvider` cache, and `lazy var` state shared across `concurrentPerform`; Mutex conversion would be invasive
- `nonisolated(unsafe)` on `RuleBasedFindingCategory.ruleType` still needed — `Rule` protocol isn't `Sendable`
