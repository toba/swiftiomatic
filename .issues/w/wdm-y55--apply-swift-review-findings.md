---
# wdm-y55
title: Apply swift-review findings
status: completed
type: task
priority: normal
created_at: 2026-03-03T01:05:23Z
updated_at: 2026-03-03T01:09:16Z
sync:
    github:
        issue_number: "158"
        synced_at: "2026-03-03T01:43:38Z"
---

Fix all 7 findings from swift-review:

- [x] **High**: Move `waitForSourceKitRestore()` outside lock in Request.swift
- [~] **Medium**: Extract shared ACL rule visitor — skipped: visitors have fundamentally different patterns (scope tracking vs top-level only)
- [~] **Medium**: Replace `Any` in RuleStorage — skipped: would require `AnyFileInfo` conformance on arrays, sets, and custom types across many files; `@unchecked Sendable` is legitimate (protected by Mutex)
- [~] **Low**: Consolidate `makeViolation` — skipped: the two implementations serve different protocol constraints (severity from options vs required in violation)
- [~] **Low**: Remove `@unchecked` from CachedRegex — skipped: `Regex<AnyRegexOutput>` is not Sendable in current Swift version
- [x] **Low**: Add `T: Sendable` constraint to Cache to remove `@unchecked` on CacheStorage
- [x] **Low**: Replace `nonisolated(unsafe)` with Mutex in FormatEngine.swift


## Summary of Changes

Applied 3 of 7 review findings:

1. **Request.swift** — Moved `waitForSourceKitRestore()` outside the `sourceKitRequestGate` lock. Previously, a SourceKit crash would hold the lock for up to 10 seconds while polling for recovery, blocking all other SourceKit requests. Now the lock is released immediately on error, and the restore wait happens outside.

2. **SwiftSource+Cache.swift** — Added `T: Sendable` constraint to `Cache<T>`, allowing the inner `CacheStorage` struct to use plain `Sendable` instead of `@unchecked Sendable`.

3. **FormatEngine.swift** — Replaced `nonisolated(unsafe) var findings` with `Mutex<[FormatFinding]>`, making thread-safety compiler-verifiable.

4 findings were investigated and skipped with justification (see checklist above).
