---
# 81e-p3o
title: Refactor Models/ files from Swift review findings
status: completed
type: task
priority: normal
created_at: 2026-02-28T18:35:13Z
updated_at: 2026-02-28T18:47:16Z
---

Apply all findings from the Swift review of `Sources/Swiftiomatic/Models/`.

## Checklist

- [x] **Medium: File I/O inside `Mutex.withLock`** — `LinterCache.fileCache(cacheDescription:)` at `LinterCache.swift:141-158` performs disk I/O and plist decoding while holding the lock. Move I/O outside the lock.
- [x] **Medium: `Date()` for benchmarking** — `Linter.swift:138` and `:408` use `Date()` for timing. Replace with `ContinuousClock.now` for monotonic timing. Cascades to `ruleTime` tuple type.
- [x] **Low: `compactMap` → `map`** — `Linter.swift:420-423` closure always returns non-optional; use `map`.
- [x] **Low: Dead `format` method** — `CollectedLinter.format(useTabs:indentWidth:)` at `Linter.swift:474-476` is a no-op. Remove method and its call sites in `LintOrAnalyzeCommand.swift:282,284`.
- [x] **Low: `DispatchQueue.concurrentPerform` → `TaskGroup`** — `Linter.collect(into:)` at `Linter.swift:301`. Make `collect` async and cascade through call chain.


## Summary of Changes

### LinterCache.swift
- Moved file I/O (`Data(contentsOf:)` + plist decode) out of `Mutex.withLock` in `fileCache(cacheDescription:)`. Split into fast-path lock check, slow-path I/O outside lock, then lock-and-store.

### Linter.swift
- Replaced `Date()` with `ContinuousClock.now` for monotonic benchmarking in `performLint` and `cachedStyleViolations`.
- Changed `compactMap` to `map` in `cachedStyleViolations` where the closure never returns nil.
- Removed dead no-op `format(useTabs:indentWidth:)` method.
- Converted `collect(into:)` from `DispatchQueue.concurrentPerform` to async `TaskGroup`.

### Benchmark.swift
- Added `Duration.timeInterval` extension for converting `Duration` to `Double` seconds.
- Changed `record(file:from:)` parameter from `Date` to `ContinuousClock.Instant`.

### LintOrAnalyzeCommand.swift
- Updated benchmark start time from `Date()` to `ContinuousClock.now`.
- Removed dead `format` call sites in `autocorrect`.

### Configuration+CommandLine.swift
- Updated `collect(into:)` call site from sync `autoreleasepool` to `await`.
