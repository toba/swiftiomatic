---
# h2d-4as
title: 'N1: Disambiguate overloaded LintPipeline.onVisitPost'
status: ready
type: task
priority: low
created_at: 2026-04-30T15:59:18Z
updated_at: 2026-04-30T15:59:18Z
parent: 6xi-be2
sync:
    github:
        issue_number: "539"
        synced_at: "2026-04-30T16:27:54Z"
---

**Location:** `Sources/SwiftiomaticKit/Syntax/Linter/LintPipeline.swift:32, 45` and `Pipelines+Generated.swift:64, 70`

`onVisitPost(rule:for:)` and `onVisitPost(_:for:)` overload to do quite different things — one cleans up `shouldSkipChildren` only, the other dispatches `visitPost` to a cached rule. Reading generated dispatch is harder than it should be.

## Potential performance benefit

None — readability only.

## Reason deferred

Rename touches generated code. Ride along with P3/P9 generator changes rather than churning it twice. Suggested names: `leaveSkipScope(rule:for:)` and `dispatchVisitPost(_:for:)`.
