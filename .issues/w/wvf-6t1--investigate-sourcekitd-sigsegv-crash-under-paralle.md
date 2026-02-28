---
# wvf-6t1
title: Investigate sourcekitd SIGSEGV crash under parallel test load
status: in-progress
type: bug
priority: low
created_at: 2026-02-28T16:18:06Z
updated_at: 2026-02-28T17:48:17Z
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
- [ ] Search LLVM/Swift bug tracker for known issues
- [ ] Consider CI workaround (e.g. ignore exit code if 0 test failures in output)

## Findings

### sourcekitdInProc is loaded in-process
The bindings load `sourcekitdInProc.framework` (not the XPC variant), so SIGSEGV kills the test process itself. The LLVM crash handler (`PLEASE submit a bug report`) is installed by sourcekitd_initialize and fires for any SIGSEGV in the process.

### Not limited to AnalyzerRule tests
5 AnalyzerRules have `requiresFileOnDisk: true` and make index/cursorInfo requests: UnusedDeclarationRule, UnusedImportRule, ExplicitSelfRule, CaptureVariableRule, TypesafeArrayInitRule. However, **every test file** triggers `Request.editorOpen` via `responseCache` in SwiftLintFile+Cache.swift (for structureDictionary, syntaxMap access). Skipping only AnalyzerRule tests still crashes.

### Serializing SourceKit requests does not fix the crash
Added a `DispatchSemaphore(value: 1)` gate around `Request.send()` and `Request.asyncSend()` — crash persists. The SIGSEGV may originate inside sourcekitdInProc from internal state corruption even with serialized requests, or from another LLVM component (SwiftParser/swift-syntax).

### Disabling SourceKit eliminates the SIGSEGV but hits a fatalError
With `SWIFTLINT_DISABLE_SOURCEKIT=1`, signal 11 is gone, but tests crash on `queuedFatalError("Never call this for file that sourcekitd fails.")` in SwiftLintFile+Cache.swift:158 because `structureDictionary` is accessed on a file where `sourcekitdFailed` is true.

### In-flight change: Request.swift serialization gate
Added `sourceKitRequestGate` semaphore in Request.swift. Correct but insufficient — the crash is deeper in sourcekitdInProc. Change is still beneficial for reducing concurrent load.

### Dead code: disableSourceKit infrastructure
`Request.disableSourceKit`, `disableSourceKitOverride`, `SWIFTLINT_DISABLE_SOURCEKIT` env var, `SourceKitDisabledError` — all dead code per project direction (SourceKit always on). Separate cleanup task.
