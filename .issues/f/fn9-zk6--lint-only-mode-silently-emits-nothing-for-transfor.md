---
# fn9-zk6
title: Lint-only mode silently emits nothing for transform-based rules
status: completed
type: bug
priority: high
created_at: 2026-05-08T04:59:09Z
updated_at: 2026-05-08T05:19:32Z
sync:
    github:
        issue_number: "650"
        synced_at: "2026-05-08T05:22:45Z"
---

`Context` documents that a rule configured with `rewrite: false, lint: .warn` should 'lint without rewriting' — but for `StaticFormatRule`s dispatched via `CompactSyntaxRewriter` / `RewritePipeline`, this isn't true.

## Mechanism

`RewritePipeline.apply` (and `applyWidening`) gate the entire `transform` invocation on `context.shouldRewrite`:

```swift
private func apply<...>(...) {
    guard context.shouldRewrite(R.self, gate: gate) else { return }
    if let next = body(concrete, original, context).as(N.self) { concrete = next }
}
```

`shouldRewrite` (RewriteContext.swift:25) checks `rewriteEnabledRules` first:

```swift
guard rewriteEnabledRules.contains(ObjectIdentifier(rule)) else { return false }
```

`rewriteEnabledRules` (Context.swift:140) only includes rules where `configuration.isRewriteActive(rule:)` is true. So when a user sets `rewrite: false`, the rule's `transform` never runs — and since the lint diagnostic (`Self.diagnose(...)`) is emitted from inside `transform`, the lint silently disappears too.

## Affected rules

Every `StaticFormatRule` that emits a finding from inside `transform`. Examples confirmed: `NoForceCast`, `UseKeyPath` (both have `defaultValue: .init(rewrite: false, lint: .warn)` or `.no` and rely on `transform` for emission).

## Symptoms

- Users who configure `{ rewrite: false, lint: "warn" }` for a transform-based rule see zero findings, contradicting the documented separation of lint vs rewrite.
- Related: this is the upstream cause of the `flagUnusedIgnoreDirective` false positives fixed in 75d-f9x — directives like `// sm:ignore:next noForceCast` looked stale because the rule never queried the mask.

## Possible fixes

1. **Decouple lint and rewrite at the dispatch layer.** Run `transform`'s diagnostic emission whenever the rule is in `enabledRules`; only apply the rewriter mutation when in `rewriteEnabledRules`. Requires either splitting `transform` into separate `diagnose` + `rewrite` hooks, or threading a 'lint-only' flag through and discarding the returned syntax.
2. **Two-pass fallback.** Add a lint-only walker (mirror of `LintPipeline`) that invokes `transform` for the side-effect diagnostics on rules that are lint-active but rewrite-inactive, ignoring the returned tree.
3. **Document the constraint** and remove the misleading 'will lint' comment from `Context.rewriteEnabledRules` — i.e. accept that `StaticFormatRule`s require `rewrite: true` to emit anything.

Option 1 is cleanest but invasive; option 3 is the smallest scope. Decide based on whether lint-only is intended to be a supported mode for transform-based rules.



## Summary of Changes

Added `isLintMode` flag to `Context.init` and threaded it from `LintCoordinator`. When set, `rewriteEnabledRules` is widened to equal `enabledRules`, so `RewritePipeline` dispatches every active rule's `transform` — including those configured `rewrite: false, lint: .warn` (e.g. `NoForceCast`, `UseKeyPath`). Findings emitted from inside `transform` (via `Self.diagnose`) now fire correctly in `sm lint`. The mutated tree produced by the pipeline is discarded by `LintCoordinator` regardless, so widening is safe.

Format mode behaviour is unchanged: `rewrite: false, lint: .warn` rules still skip dispatch in `RewriteCoordinator` runs, preserving the existing semantics that format never rewrites a rule the user disabled. (Surfacing lint findings during format mode for those rules is a wider refactor — every manual `if context.shouldRewrite(X) { result = X.transform(...) }` site in `RewritePipeline` would need to split dispatch from commit. Out of scope.)

### Files changed
- `Sources/SwiftiomaticKit/Support/Context.swift` — add `isLintMode` parameter; widen `rewriteEnabledRules` when set.
- `Sources/SwiftiomaticKit/Syntax/Linter/LintCoordinator.swift` — pass `isLintMode: true`.
- `Tests/SwiftiomaticTests/Rules/NoForceCastTests.swift` — add regression test `lintOnlyConfigEmitsFinding` driving `LintCoordinator` with the rule's default `rewrite: false, lint: .warn` config (fails before the fix; passes after).
