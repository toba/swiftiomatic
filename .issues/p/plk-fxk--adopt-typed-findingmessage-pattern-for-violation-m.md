---
# plk-fxk
title: Adopt typed Finding.Message pattern for violation messages
status: completed
type: task
priority: low
created_at: 2026-03-02T21:40:56Z
updated_at: 2026-03-02T22:46:26Z
parent: a2a-2wk
sync:
    github:
        issue_number: "138"
        synced_at: "2026-03-02T23:47:36Z"
---

Replace bare reason strings in SyntaxViolation with a typed, compile-time-checked message pattern inspired by swift-format's Finding.Message.

## Current State
- Violations use `reason: String` — free-form, no compile-time checking
- Typos and inconsistent phrasing are only caught by review
- Messages are scattered as string literals in visitor code

## Target State
- A `ViolationMessage` type (or similar) conforming to `ExpressibleByStringInterpolation`
- Each rule defines its messages as `fileprivate static` extensions on the message type
- Compile-time safety: misspelled message references fail to build
- Consistent namespace for all messages

## Tasks
- [x] Define `ViolationMessage` type with `ExpressibleByStringLiteral` and `ExpressibleByStringInterpolation`
- [x] Update `SyntaxViolation` to use `ViolationMessage` instead of `String` for reason
- [x] Migrate a pilot batch of rules (~10) to use typed messages
- [x] Evaluate ergonomics and refine the pattern
- [x] Migrate remaining rules (can be incremental — both patterns coexist during migration)


## Summary of Changes

Completed via ck1-esx. Introduced ViolationMessage type with ExpressibleByStringInterpolation, updated SyntaxViolation and RuleViolation, and migrated 7 pilot rules. Both patterns coexist for incremental migration.
