---
# y5o-v8q
title: Investigate extending RedundantSendable for @unchecked Sendable
status: ready
type: feature
priority: normal
created_at: 2026-04-30T23:13:50Z
updated_at: 2026-04-30T23:13:50Z
parent: 7h4-72k
sync:
    github:
        issue_number: "588"
        synced_at: "2026-04-30T23:14:22Z"
---

Originally part of epic 7h4-72k. Extend `Sources/SwiftiomaticKit/Rules/Redundancies/RedundantSendable.swift` to also strip `@unchecked Sendable` when:

(a) all stored fields are themselves `Sendable`, or
(b) the only "unsafe" storage is `[any P.Type]` where `P: Sendable` (SE-0470 metatype storage)

The current rule handles redundant `: Sendable` on non-public structs/enums but doesn't touch `@unchecked` cases. Investigate scope: how much of (a) needs cross-decl/type-info to be safe, vs. how much can be detected structurally.

## Plan

- [ ] Survey `@unchecked Sendable` patterns in the wild
- [ ] Identify the safe structural subset (fields with literal Sendable types, primitive types, etc.)
- [ ] Decide whether (a) and (b) are doable without semantic info
- [ ] If yes, implement; if no, scrap with notes
