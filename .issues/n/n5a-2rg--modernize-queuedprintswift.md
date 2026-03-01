---
# n5a-2rg
title: Modernize QueuedPrint.swift
status: completed
type: task
priority: normal
created_at: 2026-02-28T20:10:11Z
updated_at: 2026-02-28T20:10:11Z
sync:
    github:
        issue_number: "51"
        synced_at: "2026-03-01T01:01:38Z"
---

Replace legacy DispatchQueue-based thread-safe printing with Mutex from Synchronization framework.

- [x] Remove `@preconcurrency import Dispatch` and `@preconcurrency import Foundation`
- [x] Add `import Synchronization` and clean `import Foundation`
- [x] Replace `DispatchQueue` with `Mutex(())`
- [x] Remove `atexit` handler (writes are synchronous now)
- [x] Replace `.bridge().lastPathComponent` with `URL(filePath:).lastPathComponent`
- [x] Keep function signatures identical (no caller changes)

## Summary of Changes

Replaced the entire `Sources/Swiftiomatic/Support/QueuedPrint.swift` implementation:
- `outputQueue` (DispatchQueue) → `outputLock` (Mutex)
- Async writes → synchronous `withLock` blocks
- Removed `setupAtExitHandler()` — no longer needed since writes are synchronous
- Modernized path extraction in `queuedFatalError` to use `URL(filePath:)`
