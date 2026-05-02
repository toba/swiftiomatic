---
# 7ik-9ea
title: DropRedundantSelf strips self.X where X is the enclosing function's name
status: completed
type: bug
priority: normal
created_at: 2026-05-02T16:34:56Z
updated_at: 2026-05-02T16:39:28Z
sync:
    github:
        issue_number: "634"
        synced_at: "2026-05-02T17:32:31Z"
---

## Repro

```swift
public extension Array {
    func max(on path: KeyPath<Element, some Comparable>) -> Element? {
        self.max { $0[keyPath: path] < $1[keyPath: path] }
    }
}
```

After the rule runs:

```swift
func max(on path: KeyPath<Element, some Comparable>) -> Element? {
    max { $0[keyPath: path] < $1[keyPath: path] }
}
```

Compiler warning: *Use of 'max' treated as a reference to instance method in protocol 'Sequence'*. The bare `max` is ambiguous between the enclosing function (recursive ref) and `Sequence.max(by:)`. The compiler resolves to the protocol method by overload labels, but it warns — and in some real-world overload sets it would be an error or pick the wrong one.

## Cause

The rule's local-name shadowing check does not include the *enclosing function declaration's own name*. The enclosing function is in scope as a recursive reference within its own body, so `self.X` where X is the enclosing function name should not be stripped.

## Tasks

- [x] Add failing test: extension method whose name matches a Sequence/parent-protocol method, body calls `self.<sameName> { ... }`. After format, `self.` should remain.
- [x] Update `willEnter(FunctionDeclSyntax)` in DropRedundantSelf.swift to insert `node.name.text` into the local name set for that scope.
- [x] Confirm full suite passes.


## Summary of Changes

- `DropRedundantSelf.willEnter(FunctionDeclSyntax)` now inserts the function's own name into the scope's local name set. The shadowing check then keeps `self.<name>` when `<name>` equals the enclosing function name, preventing the rule from converting `self.max { ... }` into a recursive reference inside `func max(on:)`.
- New test: `keepSelfWhenMemberNameMatchesEnclosingFunctionName`.
- Full suite: 3197 passed.

### Files
- `Sources/SwiftiomaticKit/Rules/Redundancies/DropRedundantSelf.swift`
- `Tests/SwiftiomaticTests/Rules/DropRedundantSelfTests.swift`
