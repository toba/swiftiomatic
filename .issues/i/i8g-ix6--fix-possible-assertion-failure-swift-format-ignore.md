---
# i8g-ix6
title: 'Fix possible assertion failure: swift-format-ignore on last element of #if clause'
status: completed
type: bug
priority: normal
created_at: 2026-05-26T15:19:47Z
updated_at: 2026-05-26T15:27:28Z
sync:
    github:
        issue_number: "708"
        synced_at: "2026-05-26T15:33:27Z"
---

Upstream swift-format fix 40aef03b (swiftlang/swift-format#1210) fixes an assertion failure ("Too many unresolved delimiter token lengths") when a `// swift-format-ignore` directive is applied to the last element of a conditional-compilation (`#if`) clause:

```swift
#if FOO
// swift-format-ignore
print("Hi")
#endif
```

The ignored item's subtree is emitted as a single verbatim token, so its tokens are never visited and an `after(lastToken, ...)` group on it is dropped, leaving an `.open` unclosed → unbalanced delimiter stack.

## Tasks
- [x] Reproduce in Swiftiomatic (write failing test in IfConfig/IgnoreNode tests)
- [x] Port the upstream fix (isFormatterIgnored helper + attach close tokens before the following token)
- [x] Confirm test passes
- [x] Run full suite for regressions (deferred to /commit; filtered IgnoreNodeTests green)

Ref: ~/Developer/swiftiomatic-ref/swift-format commit 40aef03b76f4ef357bbef10bf43a6b4a09eded5a

## Summary of Changes

The bug reproduced in Swiftiomatic: a `// sm:ignore` directive on the last element of an `#if`/`#elseif`/`#else` clause crashed with `Assertion failed: Too many unresolved delimiter token lengths` (LayoutCoordinator.swift:798), because `visitIfConfigClause` (in `IndentConditionalCompilationBlocks.swift`) attaches the clause's closing `.close` via `after(node.elements?.lastToken, ...)`; an ignored last item is emitted as one verbatim token and never visited, so the `.close` was dropped and the `.open` left unbalanced.

- Added `isFormatterIgnored(_ token:)` to `CommentMovingRewriter.swift` (walks to the enclosing `CodeBlockItem`/`MemberBlockItem` and checks `shouldFormatterIgnore`), mirroring upstream swift-format 40aef03b.
- Updated `visitIfConfigClause` to attach the closing tokens before the token *after* the body (next `#elseif`/`#else`/`#endif`) when the last body token is formatter-ignored.
- Added three regression tests to `IgnoreNodeTests`: `ignoreInConditionalCompilationBlock`, `ignoreInEachConditionalCompilationClause`, `ignoreInNestedConditionalCompilationBlock`.

Filtered `IgnoreNodeTests` suite: 11 passed, 0 failed.
