---
# prs-zf4
title: nestedCallLayout inline expands SwiftUI modifier-chain call arg instead of inlining
status: completed
type: bug
priority: high
created_at: 2026-06-20T15:17:29Z
updated_at: 2026-06-20T15:28:59Z
sync:
    github:
        issue_number: "738"
        synced_at: "2026-06-20T15:31:53Z"
---

## Repro

```swift
var body: some View {
    Text(name)
        .onHover { color = $0 ? Color.accentColor : Color.clear }
        .background(RoundedRectangle(cornerRadius: 5).fill(color))
        .onTapGesture { didSelect() }
}
```

With `nestedCallLayout: { mode: inline, rewrite: true }` enabled, the already-inline (or source) `.background(RoundedRectangle(cornerRadius: 5).fill(color))` is **expanded** onto three lines instead of kept/collapsed inline.

## Root cause

In `NestedCallLayout.transform(FunctionCallExprSyntax)`, the outer call here is a SwiftUI modifier-chain element whose `calledExpression` is the entire multiline chain (`Text(name)...onHover{...}.background`). The inline strategies measure via `calledExpression.trimmedDescription` (contains newlines) and `columnOffset`/`lineIndentation` anchored on the chain's first token (`Text`), so 'fully inline' length is computed as huge -> all inline strategies fail -> Strategy 3 expands the call. `tryCollapseCallToOneLine` also bails because `collapsed.trimmedDescription` includes the chain's newlines.

## Fix

When the outermost call's callee spans multiple lines (modifier-chain element), skip the chain-rebuild strategies (their measurement is invalid) and instead collapse the sole/argument list inline, measuring only the modifier segment (`.method(args)`) at its real rendered column (anchored on the member-access period).

## Tasks
- [x] Failing test reproducing the expansion
- [x] Implement multiline-callee handling
- [x] Verify filtered tests, then full suite


## Summary of Changes

- `NestedCallLayout.transform(FunctionCallExprSyntax)` now detects when the outermost call's callee spans multiple lines (`calleeSpansMultipleLines`) — i.e. it's a wrapped member-access modifier chain element like `Text(name)…onHover {…}.background`. Such calls are routed away from the chain-rebuild strategies (whose measurement via `calledExpression.trimmedDescription` / `columnOffset` anchored on the chain root is invalid) and into a new `tryInlineModifierCallArgument`.
- `tryInlineModifierCallArgument` collapses the call's argument list inline (`collapseCallArguments`) when the modifier segment (`.method(args)`) fits on its own line, measuring only that segment at its real rendered column (anchored on the member-access period). It bails on trailing closures, comments, an already-inline body, a non-member-access callee, or a segment that wouldn't fit. The finding now anchors on the modifier name (`declName`) instead of the chain root.
- For `wrap` mode (and non-member-access multiline callees), the call is left unchanged — previously the rebuild paths mangled it by stringifying the multiline callee.
- Tests: added `modifierChainCallArgumentCollapsesInline` and `modifierChainCallArgumentAlreadyInlineUnchanged` in `NestedCallLayoutTests.swift`. Full suite green (3464 passed). Verified end-to-end on the real `thesis/App/Sources/Views/Support/FontPicker.swift` with the thesis `swiftiomatic.json` (`nestedCallLayout: inline`): the expanded `.background(...)` collapses inline and the already-inline form stays put.
