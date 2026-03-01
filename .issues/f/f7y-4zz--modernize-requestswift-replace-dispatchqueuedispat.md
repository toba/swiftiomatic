---
# f7y-4zz
title: 'Modernize Request.swift: replace DispatchQueue/DispatchSemaphore with Mutex'
status: completed
type: task
priority: normal
created_at: 2026-02-28T20:34:20Z
updated_at: 2026-02-28T20:34:20Z
sync:
    github:
        issue_number: "32"
        synced_at: "2026-03-01T01:01:34Z"
---

Replace all Dispatch-based synchronization in Request.swift with modern Synchronization framework primitives.

- [x] Replace `import Dispatch` with `import Synchronization`
- [x] Replace `sourceKitRequestGate` from `DispatchSemaphore(value: 1)` to `Mutex(())`
- [x] Replace `sourceKitWaitingRestoredSemaphore` (`DispatchSemaphore`) with `Mutex(false)` flag + `ContinuousClock` polling
- [x] Rewrite `send()` to use `sourceKitRequestGate.withLock` instead of manual wait/signal
- [x] Remove dead `asyncSend()` method (was unused — no callers in Sources/ or Tests/)
- [x] Update notification handler to set `sourceKitRestored` flag instead of signaling semaphore
- [x] Add `waitForSourceKitRestore()` helper using `ContinuousClock` + `Thread.sleep` polling
- [x] Fix deprecated `String(validatingUTF8:)` → `String(validatingCString:)`
- [x] Update `SourceKitResolver.swift` doc comment to reflect Mutex-based serialization

## Summary of Changes

Removed all `Dispatch` imports and GCD primitives from Request.swift. The request serialization gate is now a `Mutex(())` using `withLock` (scoped, no manual signal/wait). The SourceKit crash-recovery wait uses a `Mutex(false)` flag polled with `ContinuousClock` + `Thread.sleep`. The dead `asyncSend()` method was removed entirely.
