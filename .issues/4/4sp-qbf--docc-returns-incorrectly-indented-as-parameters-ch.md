---
# 4sp-qbf
title: 'DocC: ''- Returns:'' incorrectly indented as Parameters child'
status: completed
type: bug
priority: normal
created_at: 2026-05-09T15:49:57Z
updated_at: 2026-05-09T16:01:26Z
sync:
    github:
        issue_number: "677"
        synced_at: "2026-05-09T17:07:15Z"
---

## Bug

The comment reflow / DocC list handling treats `- Returns:` as a child of `- Parameters` when it appears immediately after the parameter list, indenting it under `Parameters` instead of recognizing it as a top-level DocC keyword.

### Actual output

```swift
/// Returns a single value fetched from the database for a given primary key.
///
/// - Parameters
///   - db: A database connection.
///   - primaryKey: A primary key identifying a table row.
///   - Returns: A single value decoded from the database.
```

### Expected output

```swift
/// Returns a single value fetched from the database for a given primary key.
///
/// - Parameters
///   - db: A database connection.
///   - primaryKey: A primary key identifying a table row.
/// - Returns: A single value decoded from the database.
```

`Returns:` (along with `Throws:`, `Precondition:`, `Postcondition:`, `Complexity:`, etc.) is a top-level DocC keyword and must be dedented to the same level as `- Parameters`, not nested as a parameter entry.

## Repro

Run the formatter against any function whose doc comment lists parameters followed by a `- Returns:` line, and observe that `- Returns:` is indented by two extra spaces and prefixed with the parameter-style `  - ` marker.

## Tasks

- [x] Add a failing test case in CommentReflowEngine / DocC list tests
- [x] Fix the list-item parser to recognize the DocC keyword set as top-level items even when following a Parameters block
- [x] Verify formatter output matches expected
- [x] Run full test suite for regressions



## Summary of Changes

- `Sources/SwiftiomaticKit/Rules/Comments/CommentReflowEngine.swift`
  - Added `doccTopLevelKeywords` set and `isDocCTopLevelKeyword(_:)` helper.
  - In `parseList`, break out of nested-list parsing when a DocC keyword is encountered (so the outer parser dedents it). Also break the per-item continuation loop when the next list marker is a DocC keyword, preventing infinite recursion when an over-indented keyword sits at children's indent.
  - When the outer (baseline=0) parser sees an over-indented DocC keyword, force its `leading` to baseline so it becomes a top-level sibling instead of triggering nested recursion.
- `Tests/SwiftiomaticTests/Rules/ReflowCommentsTests.swift`
  - Added `dedentsReturnsKeywordToTopLevelAfterParametersBlock` (reproduces the bug).
  - Added `preservesReturnsKeywordAlreadyAtTopLevel` (regression guard).

Full suite: 3288 / 3288 passing.
