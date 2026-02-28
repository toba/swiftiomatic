---
# wvf-6t1
title: Investigate sourcekitd SIGSEGV crash under parallel test load
status: in-progress
type: bug
priority: low
created_at: 2026-02-28T16:18:06Z
updated_at: 2026-02-28T18:30:31Z
---

## Problem

`swift test` exits with code 1 despite 0 test failures. The cause is a SIGSEGV (signal 11) in sourcekitd during parallel test execution. The crash produces an LLVM bug report message:

```
PLEASE submit a bug report to https://github.com/llvm/llvm-project/issues/ and include the crash backtrace.
```

This is an external LLVM/SourceKit bug, not a Swiftiomatic bug, but it makes CI unreliable since exit code 1 looks like a test failure.

## Observed Behavior

- 126+ tests pass, 0 failures
- sourcekitd crashes with SIGSEGV partway through the run
- Exit code is 1 (not 0) due to the crash
- Happens intermittently under parallel test load

## Investigation Areas

- [x] Determine which tests trigger sourcekitd (likely AnalyzerRule tests that call SourceKit)
- [x] Check if running SourceKit-dependent tests serialized avoids the crash
- [x] Check if disabling SourceKit-dependent tests entirely gives clean exit code 0
- [x] Search LLVM/Swift bug tracker for known issues
- [ ] Consider CI workaround (e.g. ignore exit code if 0 test failures in output)

## Findings

### sourcekitdInProc is loaded in-process
The bindings load `sourcekitdInProc.framework` (not the XPC variant), so SIGSEGV kills the test process itself. The LLVM crash handler (`PLEASE submit a bug report`) is installed by sourcekitd_initialize and fires for any SIGSEGV in the process.

### Not limited to AnalyzerRule tests
5 AnalyzerRules have `requiresFileOnDisk: true` and make index/cursorInfo requests: UnusedDeclarationRule, UnusedImportRule, ExplicitSelfRule, CaptureVariableRule, TypesafeArrayInitRule. However, **every test file** triggers `Request.editorOpen` via `responseCache` in SwiftSource+Cache.swift (for structureDictionary, syntaxMap access). Skipping only AnalyzerRule tests still crashes.

### Serializing SourceKit requests does not fix the crash
Added a `DispatchSemaphore(value: 1)` gate around `Request.send()` and `Request.asyncSend()` — crash persists. The SIGSEGV may originate inside sourcekitdInProc from internal state corruption even with serialized requests, or from another LLVM component (SwiftParser/swift-syntax).

### Disabling SourceKit eliminates the SIGSEGV but hits a fatalError
With `SWIFTLINT_DISABLE_SOURCEKIT=1`, signal 11 is gone, but tests crash on `queuedFatalError("Never call this for file that sourcekitd fails.")` in SwiftSource+Cache.swift:158 because `structureDictionary` is accessed on a file where `sourcekitdFailed` is true.

### In-flight change: Request.swift serialization gate
Added `sourceKitRequestGate` semaphore in Request.swift. Correct but insufficient — the crash is deeper in sourcekitdInProc. Change is still beneficial for reducing concurrent load.

### Dead code: disableSourceKit infrastructure
`Request.disableSourceKit`, `disableSourceKitOverride`, `SWIFTLINT_DISABLE_SOURCEKIT` env var, `SourceKitDisabledError` — all dead code per project direction (SourceKit always on). Separate cleanup task.


### Upstream bug: apple/swift#55112 (open, unfixed)
[libsourcekitdInProc.so may crash during exit](https://github.com/apple/swift/issues/55112) — background threads in sourcekitd run during static destructors, causing non-deterministic SIGSEGV. Filed by @benlangmuir. Three proposed fixes (enhanced shutdown, -fno-c++-static-destructors, out-of-process on all platforms) — none implemented. No other exact match found in Swift/LLVM trackers.

### Serial execution (`--no-parallel`) does NOT fix the crash
Ran `swift test --no-parallel` — still crashes with signal 11, exit code 1. 555 tests pass, 0 fail, then SIGSEGV kills the process during `EnumAssociableTests.nilOptionalString()` — a pure enum test with zero SourceKit usage. This confirms the crash is a **delayed SIGSEGV from sourcekitd background threads**, not from any specific SourceKit request.

### SourceKit dependency is narrow
Only ~7 rules use `structureDictionary` (SourceKit), ~9 files use `syntaxMap`. 172+ rules are already `SourceKitFreeRule` (via SwiftSyntaxRule or direct conformance). `SwiftSyntaxKindBridge` already provides a SourceKit-free alternative to `syntaxMap`. The `responseCache` factory (`Request.editorOpen`) is the sole trigger — once any test touches it, sourcekitd loads in-process and the delayed crash becomes inevitable.

### Remaining approach options (not yet implemented)
1. **CI wrapper script**: Run `swift test`, parse output, return 0 if 0 test failures + signal 11
2. **Prevent SourceKit loading in tests**: Set `SWIFTLINT_DISABLE_SOURCEKIT=1` but fix the `queuedFatalError` in `structureDictionary`/`syntaxMap` to gracefully degrade (use `assertHandler` pattern); skip tests needing real structure data
3. **Migrate remaining rules off SourceKit**: Move the ~7 `structureDictionary` users and ~9 `syntaxMap` users to swift-syntax equivalents (`SwiftSyntaxKindBridge`, AST visitors). AnalyzerRules (UnusedImportRule, CaptureVariableRule) cannot be fully migrated — they need compiler index data
4. **Use XPC sourcekitd** instead of in-process: crash wouldn't kill test process, but binding changes required
5. **`sourcekitdFailed` triggers SourceKit**: The computed property calls `responseCache.get(self)` which runs the factory. Should be refactored to use a separate flag that doesn't trigger initialization
