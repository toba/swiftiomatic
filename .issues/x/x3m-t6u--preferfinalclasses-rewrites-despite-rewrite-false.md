---
# x3m-t6u
title: 'preferFinalClasses rewrites despite `rewrite: false` in config'
status: ready
type: bug
priority: high
created_at: 2026-05-01T00:30:28Z
updated_at: 2026-05-01T00:30:28Z
sync:
    github:
        issue_number: "590"
        synced_at: "2026-05-01T00:49:16Z"
---

Companion to wy7-t4q. `preferFinalClasses` is configured with `"rewrite": false` in `swiftiomatic.json` (line 6), yet `sm format -r -p -i Sources/` added `final` to the rule base classes `LintSyntaxRule` and `StructuralFormatRule` — which are explicitly designed to be subclassed.

This broke ~80 source files (subclasses now inheriting from a final class). Reverting just those two base files restored compilation.

## Fix

`PreferFinalClasses` rewrite path likely bypasses the per-rule rewrite gate. Check that it consults `context.shouldRewrite(Self.self, gate:)` before adding `final`.

## Related

- `preferStaticOverClassFunc` did the same — converted `class var` → `static var` on `LintSyntaxRule`/`StructuralFormatRule`, breaking subclass overrides. (Set to `rewrite: false` in config — also seems to be ignored.)
- `uppercaseAcronyms` did the same (separate issue).
