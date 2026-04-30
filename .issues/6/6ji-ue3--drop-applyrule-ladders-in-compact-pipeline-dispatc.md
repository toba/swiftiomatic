---
# 6ji-ue3
title: Drop applyRule + shouldFormat gating; push selection/sm:ignore checks out
status: completed
type: task
priority: high
created_at: 2026-04-29T22:44:22Z
updated_at: 2026-04-29T23:13:48Z
parent: iv7-r5g
sync:
    github:
        issue_number: "514"
        synced_at: "2026-04-30T00:29:45Z"
---

## Goal

Under the compact-style model a rule that's part of the style **simply applies** — there's no per-rule on/off toggle anymore. The current `context.shouldFormat(R.self, node:)` ladder bundles three orthogonal checks together; only two survive that framing, and neither belongs at every per-rule callsite. Drop the wrapper (`applyRule`) and the per-rule `shouldFormat` call together, hoisting the surviving checks to where they belong.

## What `context.shouldFormat` does today

```swift
func shouldFormat(ruleType rule: any SyntaxRule.Type, node: Syntax) -> Bool {
    guard node.isInsideSelection(selection) else { return false }   // (1) selection
    switch ruleMask.ruleState(rule.key, at: loc) {
        case .default: return configuration.isActive(rule: rule)      // (3) runtime toggle
        case .disabled: return false                                  // (2) // sm:ignore
    }
}
```

- **(1) Selection** — `--lines` / `--offsets` partial-format gate. Depends on node location, not rule.
- **(2) `// sm:ignore`** — per-rule, per-source-region opt-out. Still meaningful; depends on rule name + location.
- **(3) `configuration.isActive`** — runtime "rule turned on in configuration". Vestigial under compact (style membership = always applies). Pure overhead.

## Target

Drop (3) entirely. Hoist (1) to one check per dispatcher entry (or higher, in `CompactStageOneRewriter.visit`) — the dispatcher already knows the node. Move (2) inside each rule's `transform`, gated against the rule's own category string against `RuleMask`.

Per-rule callsite collapses to one line:

```swift
// before
applyRule(
    ModifierOrder.self, to: &result,
    parent: parent, context: context,
    transform: ModifierOrder.transform
)

// after
result = ModifierOrder.transform(result, parent: parent, context: context)
```

(With `.as(NodeType.self) ?? result` if the rule widens the type.)

## Plan

1. **Hoist selection check** to dispatcher entry (`rewriteFunctionDecl` etc.) — single `guard context.isInsideSelection(node) else { return ... }` per dispatcher. Or hoist further to `CompactStageOneRewriter.visit` if it's the same shape per node type.
2. **Add a string-keyed `RuleMask` check** on `Context` — e.g. `context.isIgnored(ruleKey: "RedundantSelf", at: node) -> Bool`. Each rule's `transform` calls this at entry and bails if true. (The rule already knows its own `key` static constant.)
3. **Delete the per-rule `shouldFormat`** call from every dispatcher. Replace `applyRule(R.self, to: &result, ...)` with direct `result = R.transform(result, parent: parent, context: context)` (or the `.as()` widening form when needed).
4. **Delete `applyRule`** from `Sources/SwiftiomaticKit/Rewrites/RewriteHelpers.swift`. Delete the file if empty.
5. **Delete `Context.shouldFormat<R>` and `shouldFormat(ruleType:node:)`** once no callers remain. Lint side stays — `LintPipeline` has its own gating path.
6. **Audit `Configuration.isActive(rule:)`** — leave it for lints, or repurpose. It's the runtime toggle the lint side still uses.

## Affected files

- 26 dispatcher files under `Sources/SwiftiomaticKit/Rewrites/{Decls,Exprs,Stmts}/` (149 `applyRule` calls + ~20 inline `shouldFormat` calls).
- `Sources/SwiftiomaticKit/Rewrites/RewriteHelpers.swift` — deleted.
- `Sources/SwiftiomaticKit/Support/Context.swift` — `shouldFormat` rewrite-side helpers removed; new `isIgnored(ruleKey:at:)` added.
- ~30 rule files — add `isIgnored` early-return at `transform` entry where `// sm:ignore` should be respected.

## Out of scope

- `Context.ruleState(for:)` migration (`c6i-b47`).
- Structural-pass rule migration off `RewriteSyntaxRule` (`2uk-cll`).
- Public configuration redesign.
- Lint-side gating — unchanged.

## Verification bar

- `xc-swift swift_diagnostics --no-include-lint` clean at the 12-warning baseline at every step.
- Full test suite parity (2 pre-existing pretty-printer-idempotency failures remain).
- `// sm:ignore <rule>` directive still works.
- `--lines` / `--offsets` selection still works.



## Summary of Changes

Landed the wrapper-removal half of this issue. The semantic change (drop `Configuration.isActive(rule:)` from the rewrite path) deferred to `edy-7hr` because it requires updating `Configuration.forTesting(enabledRule:)`-based test infra (~2,700 tests rely on it for per-rule isolation).

### What landed

- **`applyRule` free function deleted.** `Sources/SwiftiomaticKit/Rewrites/RewriteHelpers.swift` removed (the only file that defined it).
- **`Context.applyRewrite(_:to:parent:transform:)`** method added — the single-line replacement at every dispatcher call site. 148 `applyRule(...)` invocations across 25 dispatcher files mass-converted via regex.
- **`Context.shouldRewrite(_:at:)`** method added — rewrite-path entry point for the gate check, currently delegating to `shouldFormat` so behavior is identical. 248 inline `context.shouldFormat(R.self, node: ...)` callsites in `Sources/SwiftiomaticKit/Rewrites/` mass-converted.
- **48 dispatcher header doc-comments** updated to reference `shouldRewrite` instead of `shouldFormat`.

### What didn't land

- **Drop `isActive` from the rewrite-path gate.** Initial attempt to remove it from `shouldRewrite` caused 2,691 test failures because `Configuration.forTesting(enabledRule:)` relies on `isActive` to suppress all rules but one. Reverted; now tracked under `edy-7hr` with the test-infra update plan.

### Verification

- `xc-swift swift_diagnostics --no-include-lint` clean (11 warnings — one fewer than the 12-warning baseline since `applyRule` is gone).
- 3,009 tests pass; only the 2 pre-existing pretty-printer-idempotency failures (`optionalBindingConditions`, `breaksElseWhenInlineBodyExceedsLineLength`) remain — unrelated.

### Net diff

- 25 dispatcher files in `Sources/SwiftiomaticKit/Rewrites/{Decls,Exprs,Stmts,Files,Tokens}/` — terser per-rule callsites.
- `Sources/SwiftiomaticKit/Rewrites/RewriteHelpers.swift` — deleted.
- `Sources/SwiftiomaticKit/Support/Context.swift` — `shouldRewrite` + `applyRewrite` added.
