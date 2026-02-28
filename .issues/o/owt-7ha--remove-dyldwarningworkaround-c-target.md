---
# owt-7ha
title: Remove DyldWarningWorkaround C target
status: ready
type: task
created_at: 2026-02-28T16:35:35Z
updated_at: 2026-02-28T16:35:35Z
---

## Context

DyldWarningWorkaround is a vendored C target (from keith/objc_dupclass) that silences dyld duplicate-class warnings when SwiftSyntax classes appear in both the system's `libSwiftSyntax.dylib` and the compiled binary. It uses `OBJC_DUPCLASS` macros on 10 SwiftSyntax/SwiftParser classes.

## Findings

- **No Swift-side import** — works purely by being linked; no `import DyldWarningWorkaround` anywhere in the codebase
- **Upstream SwiftLint still uses it** conditionally on macOS, but we are diverging from upstream maintenance anyway
- **The underlying dyld issue persists** in current Xcode/macOS — no Apple fix
- **Impact of removal**: noisy warnings on stderr, but swiftiomatic outputs JSON on stdout so stderr warnings don't affect agent consumers
- **Files involved**:
  - `Sources/DyldWarningWorkaround/DyldWarningWorkaround.c` (10 OBJC_DUPCLASS calls)
  - `Sources/DyldWarningWorkaround/include/objc_dupclass.h` (macro definition)
  - `Package.swift` (target definition + dependency reference)

## Rationale for Removal

- Reduces build complexity (one fewer C target)
- Removes vendored code we don't maintain
- Stderr warnings are cosmetic and don't affect JSON output on stdout
- Project already diverges from upstream SwiftLint; no need to carry their workarounds

## Tasks

- [ ] Remove `DyldWarningWorkaround` target from Package.swift
- [ ] Remove dependency on `DyldWarningWorkaround` from Swiftiomatic executable target
- [ ] Delete `Sources/DyldWarningWorkaround/` directory
- [ ] Build and verify no compilation errors
- [ ] Run tests to confirm no regressions
