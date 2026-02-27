---
# aj3-vmj
title: 'Check: SwiftUI layout issues (§8 — previously non-greppable)'
status: completed
type: task
priority: normal
created_at: 2026-02-27T21:36:32Z
updated_at: 2026-02-27T21:55:08Z
parent: 52u-0w0
blocked_by:
    - w7e-hbx
---

SyntaxVisitor that detects SwiftUI layout composition anti-patterns.

## Why this was impossible with grep
SwiftUI layout issues arise from the *nesting structure* of view builders, not from individual keywords. Grep can find `ScrollView` or `List` but cannot determine they are nested inside each other.

## Checks

- [ ] **Multiple unbounded containers in same parent** — find `VStack`/`HStack`/`ZStack` containing 2+ `List`, `ScrollView`, or `Form` children. Each unbounded container proposes infinite height, causing layout explosion
- [ ] **`GeometryReader` inside `ScrollView`** — `GeometryReader` inside a scroll view receives undefined proposed size (the scroll view proposes infinity). Detect `ScrollView { ... GeometryReader { } ... }` nesting
- [ ] **Nested `NavigationStack`/`NavigationView`** — `NavigationStack` inside another `NavigationStack` causes double navigation bars and broken back-button behavior
- [ ] **`List` inside `ScrollView`** — `List` has its own scrolling; wrapping it in `ScrollView` creates conflicting scroll gestures
- [ ] **`.frame(width:height:)` on expanding containers** — `List { }.frame(height: 300)` clips content without scroll; should use `ScrollView` with fixed frame instead

## AST approach

SwiftUI views are built with result builders, which in the AST appear as chained `FunctionCallExprSyntax` nodes. The approach:

1. Walk `FunctionCallExprSyntax` looking for known view types (`List`, `ScrollView`, `NavigationStack`, `GeometryReader`, `VStack`, `HStack`, `ZStack`, `Form`)
2. Track nesting depth with a stack
3. When entering a container, check if the parent stack contains a conflicting container
4. Report conflicts with the parent:child relationship

## AST nodes to visit
- `FunctionCallExprSyntax` — identify SwiftUI view constructors by name
- `MemberAccessExprSyntax` — detect `.frame()`, `.onAppear` modifiers
- Track parent chain for nesting analysis

## Confidence levels
- Nested NavigationStack → high
- List inside ScrollView → high
- GeometryReader inside ScrollView → high
- Multiple unbounded containers → medium (may use `.frame` to constrain)

## Summary of Changes
- SwiftUILayoutCheck with container nesting stack
- Detects nested NavigationStack, List in ScrollView, GeometryReader in ScrollView
- Multiple unbounded containers detection
