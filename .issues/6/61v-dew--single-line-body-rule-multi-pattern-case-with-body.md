---
# 61v-dew
title: 'Single-line body rule: multi-pattern case with body on next line not collapsed'
status: completed
type: bug
priority: normal
created_at: 2026-05-01T02:22:32Z
updated_at: 2026-05-01T02:51:37Z
sync:
    github:
        issue_number: "598"
        synced_at: "2026-05-01T03:50:33Z"
---

When the single-line body rule is enabled, a `case` with multiple patterns (one per line) and the body on the following line is not collapsed onto the pattern's last line.

## Repro

Input:
```swift
case .docBlockComment,
     .docLineComment,
     .newlines(1),
     .carriageReturns(1),
     .carriageReturnLineFeeds(1),
     .spaces,
     .tabs:
    false
```

## Expected

```swift
case .docBlockComment,
     .docLineComment,
     .newlines(1),
     .carriageReturns(1),
     .carriageReturnLineFeeds(1),
     .spaces,
     .tabs: false
```

## Actual

Body `false` stays on its own line below the colon.

## Notes

- Likely in the single-line body rule's eligibility check — multi-pattern case items split across lines may bail out, but they shouldn't: the body still belongs on the same line as the closing pattern's `:`.
- Need a reproducing test first (see CLAUDE.md test-first rule).



## Summary of Changes

- `Sources/SwiftiomaticKit/Rules/Wrap/WrapSwitchCaseBodies.swift`: in `adaptiveCase`, the line-length guard now measures only the **last line** of the label (the one carrying the colon) instead of the whole multi-line `trimmedDescription`. For multi-pattern cases split across lines, `labelText.count` previously included newlines + alignment whitespace and easily exceeded `LineLength`, causing the rule to bail out and leave the body wrapped.
- `Tests/SwiftiomaticTests/Rules/Wrap/WrapSwitchCaseBodiesTests.swift`: added `multiPatternBodyInlinesOnLastPattern` reproducing the bug (7-pattern case) and verifying the body is inlined onto the last pattern line.

Full `WrapSwitchCaseBodies` suite passes (12/12). 4 unrelated failures elsewhere in the suite (MemberAccess/Assignment/FunctionCall/IfConfig) pre-existed in the working tree from another agent's in-progress changes.
