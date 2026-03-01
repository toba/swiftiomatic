---
# 7f5-mwk
title: Split test target to fix OOM crashes and lock contention
status: scrapped
type: task
priority: high
created_at: 2026-02-28T05:48:09Z
updated_at: 2026-02-28T15:30:59Z
blocked_by:
    - 0na-1xs
sync:
    github:
        issue_number: "34"
        synced_at: "2026-03-01T01:01:35Z"
---

## Problem

Running the full test suite (or large subsets of it) crashes with **signal 137 (OOM killed)** or hangs indefinitely. The root cause is architectural: all ~500 test suites live in one test target and run in-process concurrently.

### Why it crashes

Swift Testing runs `@Suite` types concurrently within a single process. The test target contains:
- 248 generated lint suites (GeneratedTests_01–10)
- 69 lint built-in rule suites
- 173 format rule suites
- ~15 other suites (framework, core, suggest)

**Total: ~505 suites**, each potentially spinning up its own thread. Two interacting problems:

1. **OOM from concurrent lint test execution**: Each `verifyRule()` call constructs a `Configuration`, creates `SwiftSource` objects, and runs the full rule. Hundreds of these running concurrently exhaust memory. Signal 137 = kernel OOM kill.

2. **Lock serialization makes combined runs too slow**: An `NSRecursiveLock` (`lintTestLock`) was added to serialize lint test helpers (`violations()`, `verifyRule()`, `corrections()`). This prevents data races on `SwiftSource.clearCaches()` and shared `RuleRegistry` state, but when hundreds of suites queue up on the lock, the process appears hung. The lock only serializes work — threads and their memory are still all alive.

### What works now

Running tests in **small batches** (≤12 suites at a time) works fine:
- All 134 format rule suites pass (in batches of ~30)
- All 69 lint built-in rule suites pass (in batches of ~15)
- Top-level suggest tests pass
- Format infrastructure tests pass

### What doesn't work

- `swift test` (all tests) → signal 137 (OOM killed)
- `swift test --filter "GeneratedTests_01"` (25 generated suites) → signal 137
- Any filter matching >~15 lint suites simultaneously → hangs on lock contention then OOM

## Solution: Split into separate test targets

Separate test targets run in separate **processes**, solving both OOM and lock contention:

```
SwiftiomaticTests/          → suggest checks, top-level tests
SwiftiomaticFormatTests/    → format rules + infrastructure
SwiftiomaticLintTests/      → lint rules + generated + framework
```

### Tasks

- [ ] Create `SwiftiomaticFormatTests` target in Package.swift
  - Move `Tests/SwiftiomaticTests/FormatTests/` → `Tests/SwiftiomaticFormatTests/`
  - Include `FormatTestHelper.swift` and `FormatProjectPaths.swift`
- [ ] Create `SwiftiomaticLintTests` target in Package.swift
  - Move `Tests/SwiftiomaticTests/LintTests/` → `Tests/SwiftiomaticLintTests/`
  - Include `LintTestHelpers.swift`
- [ ] Keep `SwiftiomaticTests` for suggest/top-level tests only
- [ ] Verify each target runs independently: `swift test --target SwiftiomaticFormatTests`
- [ ] Verify `swift test` (all targets) completes without OOM
- [ ] If lint generated tests still OOM in their own process, split further into `SwiftiomaticLintGeneratedTests`

## Context

- Lock in `LintTestHelpers.swift:70` (`lintTestLock`) should remain even after split — it still prevents intra-process races
- `.serialized` trait on suites should remain — it prevents intra-suite races
- Format tests may also need a lock (format engine has `nonisolated(unsafe) static var` globals)
- 28 tests are disabled with `.disabled("reason")` — don't re-enable during this work
