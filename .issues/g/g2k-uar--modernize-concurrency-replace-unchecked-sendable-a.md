---
# g2k-uar
title: 'Modernize concurrency: replace @unchecked Sendable and DispatchQueue'
status: ready
type: task
priority: normal
created_at: 2026-04-14T02:42:22Z
updated_at: 2026-04-14T02:42:22Z
parent: kqx-iku
sync:
    github:
        issue_number: "274"
        synced_at: "2026-04-14T02:58:31Z"
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
- [ ] Evaluate Frontend classes for Mutex conversion
- [ ] Convert StderrDiagnosticPrinter DispatchQueue to Mutex
- [ ] Check if RuleBasedFindingCategory nonisolated(unsafe) is still needed (SE-0470)
- [ ] Build and test
