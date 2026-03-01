---
# nw7-38c
title: Evaluate use of SourceKit
status: completed
type: task
priority: normal
created_at: 2026-02-27T22:16:12Z
updated_at: 2026-02-27T22:56:47Z
sync:
    github:
        issue_number: "56"
        synced_at: "2026-03-01T01:01:39Z"
---

Evaluate use of SourceKit https://github.com/swiftlang/swift/tree/main/tools/SourceKit



## Summary of Changes

Evaluated and integrated via SourceKitten (bjw-ozq). SourceKitService target added with cursorinfo, index, and expression-type requests. Used for USR-based dead symbol matching in DeadSymbolsCheck. Compiles under .swiftLanguageMode(.v5) due to SourceKittenFramework limitations.
