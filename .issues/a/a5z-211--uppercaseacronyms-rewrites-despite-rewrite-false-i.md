---
# a5z-211
title: 'uppercaseAcronyms rewrites despite `rewrite: false` in config'
status: ready
type: bug
priority: high
created_at: 2026-05-01T00:30:17Z
updated_at: 2026-05-01T00:30:17Z
sync:
    github:
        issue_number: "592"
        synced_at: "2026-05-01T00:49:16Z"
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
