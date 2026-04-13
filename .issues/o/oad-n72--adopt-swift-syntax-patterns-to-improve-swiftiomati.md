---
# oad-n72
title: Adopt swift-syntax patterns to improve Swiftiomatic
status: in-progress
type: epic
priority: normal
created_at: 2026-04-12T23:53:37Z
updated_at: 2026-04-13T00:00:11Z
sync:
    github:
        issue_number: "239"
        synced_at: "2026-04-13T00:25:18Z"
---

Insights from reviewing the swift-syntax source at `~/Developer/apple/swift-syntax` that could improve Swiftiomatic's correction pipeline, diagnostic model, formatting infrastructure, and IDE performance.

Reference: cited in `.jig.yaml` under `citations:` — `swiftlang/swift-syntax` (main branch).

## Not Pursued

**Arena allocation** — swift-syntax's `BumpPtrAllocator` and `RawSyntaxArena` are internal parser optimizations. Our caching at the `SwiftSource` level achieves similar benefits at a higher layer.

**Custom Traits** — Protocol-based uniform access (e.g., `.introducer` on all declaration types) could reduce some pattern matching in rules, but our visitor pattern already dispatches by node type effectively.
