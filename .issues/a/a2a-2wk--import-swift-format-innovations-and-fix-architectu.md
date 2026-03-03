---
# a2a-2wk
title: Import swift-format innovations and fix architectural debt
status: completed
type: epic
priority: normal
created_at: 2026-03-02T21:40:10Z
updated_at: 2026-03-03T00:56:15Z
sync:
    github:
        issue_number: "135"
        synced_at: "2026-03-03T01:43:38Z"
---

Surgically import swift-format's best ideas (pretty-printer, generated dispatch, typed messages) into swiftiomatic while fixing the architectural debt identified in the comparison review.

## Goals
- Replace the iterative token-based format engine with swift-format's Oppen-style pretty-printer
- Generate per-node-type lint dispatch to eliminate ~300 redundant tree walks per file
- Auto-generate the rule registry to eliminate silent registration failures
- Consolidate correction mechanisms from 3 to 2
- Adopt typed finding messages for compile-time safety

## Non-Goals
- Forking swift-format wholesale
- Importing swift-format's rules (we have superset coverage)
- Changing the scope/severity/confidence model (it's correct for our use case)

## References
- swift-format architecture: https://github.com/swiftlang/swift-format
- Comparison analysis completed 2026-03-02
