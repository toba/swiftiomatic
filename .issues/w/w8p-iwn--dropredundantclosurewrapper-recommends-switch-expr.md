---
# w8p-iwn
title: '`dropRedundantClosureWrapper` recommends switch-expression in argument position, which doesn''t compile'
status: completed
type: bug
priority: high
created_at: 2026-05-08T19:10:17Z
updated_at: 2026-05-08T19:15:41Z
sync:
    github:
        issue_number: "667"
        synced_at: "2026-05-08T19:20:43Z"
---

\`dropRedundantClosureWrapper\` flags an immediately-invoked closure containing a single \`switch\`, recommending the switch be used directly. But Swift 5.9+ \`switch\` expressions are **only allowed in return, throw, or as the source of an assignment** — not in argument position.

## Repro

\`\`\`swift
let batch = await nextRecordZoneChangeBatch(
    reason: .scheduled,
    options: options,
    syncEngine: {
        switch scope {
            case .private: `private`
            case .shared: shared
            case .public: fatalError("Public not supported")
            @unknown default: fatalError("Unknown scope")
        }
    }(),
)
\`\`\`

\`sm lint\` flags this with \`[dropRedundantClosureWrapper] remove immediately-invoked closure; use the expression directly\`. Removing the IIFE — \`syncEngine: switch scope { ... }\` — produces:

\`\`\`
error: 'switch' may only be used as expression in return, throw, or as the source of an assignment
\`\`\`

## Expected

The rule should not recommend dropping the closure wrapper when the closure body is a \`switch\`/\`if\`/\`do\` expression and the call site is an argument, subscript, or other position where Swift does not yet permit control-flow expressions. The auto-rewrite (\`rewrite: true\`) is unsafe here — running \`sm format\` would silently break the build.



## Summary of Changes

- `DropRedundantClosureWrapper` now skips the rewrite when the closure body is a `switch`/`if` expression and the call site is not in an assignment-like position (variable initializer, `return`, `throw`, or assignment RHS).
- Added `isControlFlowExpression` and `isAssignmentLikePosition` helpers in `Sources/SwiftiomaticKit/Rules/Redundancies/DropRedundantClosureWrapper.swift`.
- Added tests covering switch-in-argument (no-op), if-in-argument (no-op), and switch-in-initializer (still rewritten).
