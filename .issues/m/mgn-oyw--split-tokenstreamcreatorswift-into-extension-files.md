---
# mgn-oyw
title: Split TokenStreamCreator.swift into extension files
status: completed
type: task
priority: normal
created_at: 2026-04-19T02:48:59Z
updated_at: 2026-04-19T03:00:04Z
sync:
    github:
        issue_number: "329"
        synced_at: "2026-04-23T05:30:22Z"
---

- [x] Change access control (private → internal)
- [x] Extract CommentMovingRewriter.swift
- [x] Extract +Helpers.swift
- [x] Extract +TokenAppending.swift
- [x] Extract +TokenHandling.swift
- [x] Extract +TypeDeclarations.swift
- [x] Extract +FunctionDeclarations.swift
- [x] Extract +ControlFlow.swift
- [x] Extract +Collections.swift
- [x] Extract +Closures.swift
- [x] Extract +MembersAndBlocks.swift
- [x] Extract +TypesAndPatterns.swift
- [x] Extract +Operators.swift
- [x] Extract +Bindings.swift
- [x] Extract +StringLiterals.swift
- [x] Extract +Miscellaneous.swift
- [x] Build and verify


## Summary of Changes

Split 4,907-line TokenStreamCreator.swift into 17 files using a forwarding pattern (Swift doesn't allow override in extensions). Main file has thin stubs; implementations live in focused extension files. Also extracted +ContextualBreaks.swift (not in original plan). Build passes.
