---
# ojf-4w0
title: 'for-where clause: brace placement and indentation wrong when for header wraps'
status: review
type: bug
priority: normal
created_at: 2026-04-30T16:47:23Z
updated_at: 2026-04-30T18:05:49Z
sync:
    github:
        issue_number: "565"
        synced_at: "2026-04-30T18:07:55Z"
---

## Problem

When the formatter wraps a `for ... where ...` loop header, it produces:

```swift
for match in regex.matches(in: text, options: [], range: range)
where match.numberOfRanges > 1 {
```

The `where` clause is not indented as a continuation, and the opening brace `{` stays inline with the `where` clause.

## Expected

```swift
for match in regex.matches(in: text, options: [], range: range)
    where match.numberOfRanges > 1
{
```

The `where` should be indented as a continuation of the wrapped header, and the opening brace should drop to its own line (consistent with how wrapped `if`/`guard`/`func` signatures place the brace).

## Repro

Format any `for-in-where` loop whose header exceeds the line limit so that the `where` clause needs to wrap.

## Notes

Likely lives in token-stream construction for `ForStmtSyntax` / `WhereClauseSyntax`. Compare against upstream apple/swift-format behavior at `~/Developer/swiftiomatic-ref/swift-format/Sources/SwiftFormat/PrettyPrint/TokenStreamCreator.swift` (visit ForStmt / WhereClause).

Fixed: for-where header wrap test passes; uses upstream's same-indent for where keyword.
