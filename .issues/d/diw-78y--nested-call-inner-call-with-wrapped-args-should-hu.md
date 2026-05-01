---
# diw-78y
title: 'Nested call: inner call with wrapped args should hug outer call''s open paren'
status: completed
type: bug
priority: normal
created_at: 2026-05-01T02:14:01Z
updated_at: 2026-05-01T02:25:50Z
sync:
    github:
        issue_number: "597"
        synced_at: "2026-05-01T03:50:33Z"
---

When formatting `outer(inner(args...))` and the inner call's arguments wrap, the inner call's open paren should stay on the same line as the outer call's open paren — not break onto its own line.

## Repro

Input:
```swift
edits.append(createGroupEdit(groupName: groupName, items: items, source: source, layout: layout))
```

Current (bad) output:
```swift
edits.append(
    createGroupEdit(
        groupName: groupName,
        items: items,
        source: source,
        layout: layout
))
```

Expected:
```swift
edits.append(createGroupEdit(
    groupName: groupName,
    items: items,
    source: source,
    layout: layout
))
```

The outer `(` should hug `createGroupEdit(`. Only the inner call's args wrap; the outer call shouldn't insert an extra break before its sole argument when that argument is itself a call expression.

## Notes

- This is the `nestedCallLayout=inline` family of behavior (see related bug qo0-blv).
- User reports having flagged this pattern multiple times — likely a recurring symptom of the same underlying break-precedence issue around outer-call open-paren when the sole arg is a wrapped call.



## Summary of Changes

- `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Appending.swift` — added `FunctionCallExprSyntax` to the compact-single-arg whitelist in `isCompactSingleFunctionCallArgument`. When an outer call's sole argument is a nested function call, the outer's `(` no longer breaks before the inner call — the inner `(` hugs the outer `(` and only the inner args wrap. Labeled single-arg case (`outer(label: inner(...))`) is covered by the same check (keys on `argumentList.count == 1`).
- `Tests/SwiftiomaticTests/Layout/FunctionCallTests.swift` — added regression tests `nestedCallHugsOuterParen` and `labeledNestedCallHugsOuterParen`.
