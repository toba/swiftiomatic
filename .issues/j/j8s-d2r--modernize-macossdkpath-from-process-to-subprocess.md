---
# j8s-d2r
title: Modernize macOSSDKPath() from Process to Subprocess
status: completed
type: task
priority: low
created_at: 2026-04-11T17:56:25Z
updated_at: 2026-04-11T18:18:15Z
sync:
    github:
        issue_number: "186"
        synced_at: "2026-04-11T18:44:01Z"
---

In `Tests/SwiftiomaticTests/Support/LintTestHelpers.swift:56-67`, `macOSSDKPath()` uses the legacy `Process` + `Pipe` + `waitUntilExit()` pattern to get the macOS SDK path via `xcrun --show-sdk-path`.

Modernizing to `Subprocess` (swift-subprocess) requires making the function `async`, which cascades through:
- `makeCompilerArguments()` (called on `SwiftSource`)
- All callers in `violations()`, `assertCorrection()`, `testCorrection()`, etc.

### Resolution

Option 1+2 hybrid: made `macOSSDKPath()` async with `Subprocess.run()` and cached the result with `Mutex<String?>`. All callers were already async so cascade was minimal (just `makeCompilerArguments()`).

Moved SDK path resolution to its own file (`SDKPath.swift`) to avoid `Subprocess.Configuration` / `SwiftiomaticKit.Configuration` name clash (separate issue `xsm-oy1` filed for the underlying enum-shadows-module problem).

### Original Options
1. **Make the chain async** — most correct, but touches many test helpers
2. **Cache the SDK path in a lazy var** — call `Subprocess` once at test setup, store the result; `macOSSDKPath()` becomes a simple property read. Minimal cascade.
3. **Leave as-is** — `Process` works fine for a one-shot test helper

Option 2 is likely the best tradeoff.


## Summary of Changes

- **New file:** `Tests/SwiftiomaticTests/Support/SDKPath.swift` — async `macOSSDKPath()` using `Subprocess.run()` with `Mutex` cache
- **Modified:** `Tests/SwiftiomaticTests/Support/LintTestHelpers.swift` — removed old `Process`-based `macOSSDKPath()`, made `makeCompilerArguments()` async, added `await` at 4 call sites
- **Modified:** `Package.swift` — added `swift-subprocess` 0.4.x dependency (test target only)
