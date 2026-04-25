---
# skr-zyu
title: 'Frontend parallelism: DispatchQueue → TaskGroup, stream files'
status: completed
type: task
priority: high
created_at: 2026-04-25T20:41:34Z
updated_at: 2026-04-25T20:51:47Z
parent: 0ra-lks
sync:
    github:
        issue_number: "426"
        synced_at: "2026-04-25T22:35:10Z"
---

The current parallel pipeline blocks GCD worker threads on synchronous file I/O and materializes every file before dispatching.

## Findings

- [x] `Sources/Swiftiomatic/Frontend/Frontend.swift:308-313` — `FileIterator(...).compactMap(openAndPrepareFile)` opened *every* file synchronously up front (reading all source data into memory) before dispatch. **Fixed**: now materializes only URLs (cheap path strings); each worker opens + reads its own file.
- [ ] `Sources/Swiftiomatic/Frontend/Frontend.swift` — DispatchQueue → TaskGroup migration **deferred**. Requires `AsyncParsableCommand` migration through the entire CLI command chain plus async file I/O (Foundation does not provide portable async file reads). `concurrentPerform` is appropriate for CPU-bound parse+format work; the GCD-blocking concern only mattered when reads happened *before* dispatch (now fixed by streaming). Tracking as separate work if/when async-CLI migration happens.

## Test plan
- [x] Existing `--parallel` semantics unchanged: only the per-task body changed (open inside worker), parallelism factor and ordering identical.
- [ ] Empirical large-repo benchmark not run in this task; the change is structural — peak memory drops from O(total source bytes) to O(workers × file size) by construction.

## Summary of Changes

`Frontend.processURLs(_:parallel:)` now streams files to workers instead of materializing every `FileToProcess` (which reads each file into memory) before dispatch.

- Replaced the eager `FileIterator(...).compactMap(openAndPrepareFile)` with `Array(FileIterator(...))` (URLs only).
- Each `concurrentPerform` worker now calls `openAndPrepareFile(at:)` for its assigned URL and then `processFile`.
- Memory footprint drops from O(total source bytes) → O(workers × per-file size) for large trees.
- Disk reads now happen *inside* the worker (was sequential, before dispatch). Net wall-clock should be neutral-to-better since reads overlap with parsing on other workers.
- TaskGroup migration deferred: would require `AsyncParsableCommand` chain + async file I/O which Foundation does not readily provide. The original "GCD blocks on I/O" objection is moot now that I/O happens in the worker (any concurrency primitive blocks a thread on sync I/O).
