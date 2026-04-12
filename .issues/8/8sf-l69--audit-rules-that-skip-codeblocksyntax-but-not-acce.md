---
# 8sf-l69
title: 'Audit: rules that skip `CodeBlockSyntax` but not `AccessorBlockSyntax`'
status: ready
type: bug
priority: high
created_at: 2026-04-12T20:54:23Z
updated_at: 2026-04-12T20:54:23Z
sync:
    github:
        issue_number: "235"
        synced_at: "2026-04-12T21:03:03Z"
---

## Problem

Three rules skip `CodeBlockSyntax` children to avoid walking into local scopes but don't also skip `AccessorBlockSyntax`. Computed property / subscript bodies use `AccessorBlockSyntax`, not `CodeBlockSyntax`, so declarations inside them are incorrectly treated as top-level.

This is the same bug fixed in `PrefixedTopLevelConstantRule` (uye-na5).

## Affected Rules

- `MissingDocsRule` — may flag doc comments inside computed property bodies
- `ExplicitACLRule` — may flag access control on local `let` bindings inside computed properties
- `ExplicitTopLevelACLRule` — may flag access control on local declarations inside computed properties

## Fix

Add to each visitor:
```swift
override func visit(_: AccessorBlockSyntax) -> SyntaxVisitorContinueKind {
    .skipChildren
}
```

Also audit for missing `ClosureExprSyntax` skips if relevant.

## Validation

Run `RuleExampleTests` for each rule after fixing — add a computed-property non-triggering example if one doesn't exist.
