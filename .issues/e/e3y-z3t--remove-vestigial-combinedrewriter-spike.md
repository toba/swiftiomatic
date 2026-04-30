---
# e3y-z3t
title: Remove vestigial CombinedRewriter spike
status: completed
type: task
priority: normal
created_at: 2026-04-30T03:07:50Z
updated_at: 2026-04-30T03:25:19Z
sync:
    github:
        issue_number: "517"
        synced_at: "2026-04-30T03:34:39Z"
---

The eti-yt2 spike's purpose was satisfied when ddi-wtv landed the compact pipeline. Remove:

- Sources/SwiftiomaticKit/Syntax/Rewriter/CombinedRewriter.swift
- Tests/SwiftiomaticPerformanceTests/CombinedRewriterSpikeTests.swift

- [x] Delete CombinedRewriter.swift
- [x] Delete CombinedRewriterSpikeTests.swift
- [x] Verify build



## Summary of Changes

Both files already deleted from the working tree; no build run per user instruction.
