---
# yvy-zc5
title: Mirror SwiftLint legacy_swiftui_aspect_ratio rule (prefer scaledToFit/scaledToFill)
status: completed
type: feature
priority: normal
created_at: 2026-07-30T02:52:50Z
updated_at: 2026-07-30T03:00:36Z
sync:
    github:
        issue_number: "757"
        synced_at: "2026-07-30T03:27:17Z"
---

Port realm/SwiftLint's LegacySwiftUIAspectRatioRule (added in SwiftLint #6609, commit c733e25a) as a Swiftiomatic rule.

## Background
SwiftLint added an opt-in idiomatic rule 'legacy_swiftui_aspect_ratio': prefer `.scaledToFit()` / `.scaledToFill()` over `.aspectRatio(contentMode: .fit)` / `.aspectRatio(contentMode: .fill)` with a constant content mode. It ships an autocorrect (rewriter).

Reference: ~/Developer/... SwiftLint at Source/SwiftLintBuiltInRules/Rules/Idiomatic/LegacySwiftUIAspectRatioRule.swift

## Behavior to mirror
Triggering:
- `view.aspectRatio(contentMode: .fit)` -> `view.scaledToFit()`
- `view.aspectRatio(contentMode: .fill)` -> `view.scaledToFill()`
- `view.aspectRatio(contentMode: ContentMode.fit)` -> `view.scaledToFit()`
- `view.aspectRatio(contentMode: ContentMode.fill)` -> `view.scaledToFill()`
- bare `aspectRatio(contentMode: .fit)` -> `scaledToFit()`

Non-triggering (must NOT fire):
- ratio arg present: `view.aspectRatio(ratio, contentMode: .fit)`
- non-constant content mode: `view.aspectRatio(contentMode: contentMode)`, ternary, custom enum `CustomMode.fit`
- already `scaledToFit()` / `scaledToFill()`

## Design notes
- Node-local FunctionCallExpr rewrite -> fits StaticFormatRule<V> (see CLAUDE.md rule model). Match calledExpression member access baseName == 'aspectRatio', single argument labeled 'contentMode' whose value is a member access with baseName .fit/.fill (allow optional explicit ContentMode base). Rewrite to member access .scaledToFit/.scaledToFill with empty arg list, preserving base + trivia.
- Fits alongside existing SwiftUI-aware rules (DropRedundantViewBuilder, MakeStateVarsPrivate).

## Test first
Add a test asserting each triggering + non-triggering example before implementing (per project rules).

## Summary of Changes

Ported as `UseScaledToFit` (group: `swiftui`), a node-local `StaticFormatRule<BasicRuleValue>` on `FunctionCallExprSyntax`.

### Files
- **Added** `Sources/SwiftiomaticKit/Rules/Swiftui/UseScaledToFit.swift` — matches `<base>.aspectRatio(...)` or bare `aspectRatio(...)`; requires exactly one `contentMode:` arg whose value is a constant `.fit`/`.fill` (implicit or explicit `ContentMode.fit`), no trailing closures. Rewrites to `.scaledToFit()`/`.scaledToFill()`, dropping args and preserving trivia. Guards mirror SwiftLint's `isSwiftUIContentModeConstant` so `CustomMode.fit` and non-constant modes are left alone.
- **Added** `Tests/SwiftiomaticTests/Rules/Swiftui/UseScaledToFitTests.swift` — 11 tests (6 triggering incl. explicit ContentMode base, bare call, mid-chain; 5 non-triggering: ratio arg, variable mode, ternary, custom enum base, already-scaledToFit).
- **Edited** `Sources/SwiftiomaticKit/Syntax/Rewriter/RewritePipeline.swift` — added `apply(UseScaledToFit.self, ...)` dispatch in `visit(FunctionCallExprSyntax)` (hand-written CompactSyntaxRewriter needs manual dispatch). Non-widening `apply` since the rewrite stays a FunctionCallExpr.

### Notes
- Defaults active (rewrite), consistent with other format rules — `scaledToFit()`/`scaledToFill()` are exact SwiftUI equivalents, so the transform is semantics-preserving.
- Config registration is automatic via the GenerateCode build plugin (verified in the generated registry).
- Full suite: 3491 passed, 0 failed.
