---
# wvf-6t1
title: Investigate sourcekitd SIGSEGV crash under parallel test load
status: in-progress
type: bug
priority: low
created_at: 2026-02-28T16:18:06Z
updated_at: 2026-02-28T17:16:26Z
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

- [ ] Determine which tests trigger sourcekitd (likely AnalyzerRule tests that call SourceKit)
- [ ] Check if running SourceKit-dependent tests serialized avoids the crash
- [ ] Check if disabling SourceKit-dependent tests entirely gives clean exit code 0
- [ ] Search LLVM/Swift bug tracker for known issues
- [ ] Consider CI workaround (e.g. ignore exit code if 0 test failures in output)
