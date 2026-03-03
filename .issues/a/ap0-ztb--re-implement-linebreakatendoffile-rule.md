---
# ap0-ztb
title: Re-implement linebreakAtEndOfFile rule
status: completed
type: bug
priority: high
created_at: 2026-03-03T00:22:30Z
updated_at: 2026-03-03T00:36:08Z
parent: cix-9mb
sync:
    github:
        issue_number: "155"
        synced_at: "2026-03-03T00:54:47Z"
---

The `linebreakAtEndOfFile` FormatRule was lost in commit 749ddf4. Needs rewrite as SwiftSyntax rule (or verify swift-format handles this).

**What it did:** Ensure files end with exactly one trailing newline.

Original at `Sources/Swiftiomatic/Rules/Whitespace/LineEndings/LinebreakAtEndOfFile.swift` (749ddf4^).

- [ ] Verify if swift-format already handles this
- [ ] If not, rewrite as SwiftSyntaxCorrectableRule
- [ ] Add tests
- [ ] Register in RuleRegistry

\n## Summary of Changes\nAlready covered by existing TrailingNewlineRule (id: trailing_newline). No new implementation needed.
