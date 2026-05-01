---
# a5z-211
title: 'uppercaseAcronyms rewrites despite `rewrite: false` in config'
status: completed
type: bug
priority: high
created_at: 2026-05-01T00:30:17Z
updated_at: 2026-05-01T02:11:00Z
sync:
    github:
        issue_number: "592"
        synced_at: "2026-05-01T02:12:28Z"
---

## Repro

In configuration:
```json
"uppercaseAcronyms": { "lint": "warn", "rewrite": false, "words": [...] }
```

Yet `sm format -r -p -i Sources/` renamed `WarnForEachIdSelf` → `WarnForEachIDSelf` (class + filename + config key all changed). Tests broke until callers were updated.

Discovered while running c12-swt dogfood — every other rule with `rewrite: false` was respected; `uppercaseAcronyms` was the lone offender.

## Likely cause

The rewrite path in `UppercaseAcronyms` (`Sources/SwiftiomaticKit/Rules/Naming/UppercaseAcronyms.swift`) is probably gated on `isActive`/`shouldRewrite` for the lint pass but not for the identifier rewrite, OR `group: .naming` causes a different code path that bypasses the per-rule rewrite gate.

## Fix

Check that `UppercaseAcronyms` consults `context.shouldRewrite(Self.self, gate:)` before rewriting any identifier.


## Summary of Changes

Same root cause as x3m-t6u (preferFinalClasses) — the rewrite path was gated on `enabledRules` (lint OR rewrite active) instead of a narrower rewrite-only set. Fixed via the new `Context.rewriteEnabledRules` set, used by both `shouldRewrite(_:at:)` and `shouldRewrite(_:gate:)`. `UppercaseAcronyms` is dispatched from `LayoutWriter.applyUppercaseAcronyms` via `context.shouldRewrite(UppercaseAcronyms.self, ...)`, so the fix applies automatically — no rule-specific change needed.

Regression coverage in `Tests/SwiftiomaticTests/API/RewriteGateTests.swift` includes a `uppercaseAcronymsLintsButDoesNotRewriteWhenRewriteFalse()` case. All 3141 tests pass.

See x3m-t6u for the full file list.
