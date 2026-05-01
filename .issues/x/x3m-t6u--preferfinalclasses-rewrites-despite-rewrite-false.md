---
# x3m-t6u
title: 'preferFinalClasses rewrites despite `rewrite: false` in config'
status: completed
type: bug
priority: high
created_at: 2026-05-01T00:30:28Z
updated_at: 2026-05-01T02:10:53Z
sync:
    github:
        issue_number: "590"
        synced_at: "2026-05-01T02:12:28Z"
---

Companion to wy7-t4q. `preferFinalClasses` is configured with `"rewrite": false` in `swiftiomatic.json` (line 6), yet `sm format -r -p -i Sources/` added `final` to the rule base classes `LintSyntaxRule` and `StructuralFormatRule` — which are explicitly designed to be subclassed.

This broke ~80 source files (subclasses now inheriting from a final class). Reverting just those two base files restored compilation.

## Fix

`PreferFinalClasses` rewrite path likely bypasses the per-rule rewrite gate. Check that it consults `context.shouldRewrite(Self.self, gate:)` before adding `final`.

## Related

- `preferStaticOverClassFunc` did the same — converted `class var` → `static var` on `LintSyntaxRule`/`StructuralFormatRule`, breaking subclass overrides. (Set to `rewrite: false` in config — also seems to be ignored.)
- `uppercaseAcronyms` did the same (separate issue).


## Summary of Changes

Root cause: `Context.shouldRewrite` was a thin wrapper around `shouldFormat`, which gates on the `enabledRules` set. That set is populated from `Configuration.isActive(rule:)` whose value is `rewrite || lint.isActive` — so any rule with `lint: .warn` was treated as "active" for the rewrite path even when `rewrite: false`.

Fix: introduced a separate `rewriteEnabledRules: Set<ObjectIdentifier>` on `Context`, populated from a new `Configuration.isRewriteActive(rule:)` that consults only the `rewrite` flag. Both `Context.shouldRewrite(_:at:)` and the gate-based `Context.shouldRewrite(_:gate:)` now use this narrower set, so a rule configured with `rewrite: false, lint: .warn` lints without rewriting.

Stage-1 dispatch (`RewritePipeline.apply` / `applyWidening`) and stage-2 dispatch (`RewriteCoordinator.runStructuralPass` via `shouldRewrite`) both flow through the same gate, so this fixes `preferFinalClasses`, `uppercaseAcronyms`, `preferStaticOverClassFunc`, and any future rule that relies on the documented per-rule rewrite flag.

Files:
- `Sources/ConfigurationKit/SyntaxRuleValue.swift` — added `isRewriteActive` extension
- `Sources/SwiftiomaticKit/Configuration/Configuration.swift` — added `isRewriteActive(rule:)`
- `Sources/SwiftiomaticKit/Syntax/SyntaxRule.swift` — added `defaultRewriteActive`
- `Sources/SwiftiomaticKit/Support/Context.swift` — added `rewriteEnabledRules`, rewrote `shouldRewrite(_:at:)`
- `Sources/SwiftiomaticKit/Syntax/Rewriter/RewriteContext.swift` — gate-based `shouldRewrite` uses `rewriteEnabledRules`
- `Tests/SwiftiomaticTests/API/RewriteGateTests.swift` — regression tests for both rules

All 3141 tests pass.
