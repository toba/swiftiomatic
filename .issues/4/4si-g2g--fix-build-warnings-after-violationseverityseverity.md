---
# 4si-g2g
title: Fix build warnings after ViolationSeverity→Severity rename
status: completed
type: bug
priority: normal
created_at: 2026-03-01T19:53:36Z
updated_at: 2026-03-03T01:22:05Z
sync:
    github:
        issue_number: "127"
        synced_at: "2026-03-03T01:43:38Z"
---

Build warnings/errors after ViolationSeverity→Severity rename and BridgeExtensions.swift deletion.

## Tasks
- [x] Build to capture all warnings/errors
- [x] Fix each warning
- [x] Rebuild to verify clean build

## Summary of Changes

### Build errors fixed:
1. **`ViolationCollectingRewriter` marked `final` but subclassed** — removed `final`, converted `lazy var` properties to `let` (initialized in `init`) to avoid Swift 6 SILGen crash with key paths on non-final generic classes
2. **`ViolationCollectingVisitor` `lazy var locationConverter`** — converted to `let` for same reason  
3. **`LegacyFunctionVisitor` and `LegacyFunctionRewriter` marked `final` but subclassed** — removed `final`
4. **Compiler crash (signal 5) in `Configuration+Parsing.swift`** — key path `\.value.runsWithCompilerArguments` on existential metatype dict crashes SILGen; replaced with closure
5. **Unused `ruleIdx` variable in `Linter.swift`** — removed unnecessary `.enumerated()`
