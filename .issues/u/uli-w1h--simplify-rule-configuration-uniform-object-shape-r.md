---
# uli-w1h
title: 'Simplify rule configuration: uniform object shape, remove shorthand'
status: completed
type: feature
priority: normal
created_at: 2026-04-23T02:14:46Z
updated_at: 2026-04-23T02:24:44Z
sync:
    github:
        issue_number: "336"
        synced_at: "2026-04-23T05:30:24Z"
---

Remove shorthand config syntax. Every rule uses uniform object shape:
- `rewrite: bool` (replaces `enabled`)
- `lint: "warn" | "error" | "no"` (replaces `.none`)
- Compact single-line JSON dump for objects fitting in 100 columns

## Tasks
- [x] Rename `Lint.none` → `Lint.no`
- [x] Rename `enabled` → `rewrite`, remove shorthand decoding
- [x] Update 10 custom config structs
- [x] Update opt-in rule defaults and LintSyntaxRule base
- [x] Update Context.shouldFormat and Configuration helpers
- [x] Compact JSON dump
- [x] Update schema generator
- [x] Update RuleCollector
- [x] Update tests
- [x] Update swiftiomatic.json
- [x] Build and verify


## Summary of Changes

Simplified rule configuration to use a uniform object shape. Every rule now has `rewrite` (bool) and `lint` ("warn"/"error"/"no") properties. Removed shorthand decoding (`true`, `"warn"` etc). Added compact single-line JSON dump for objects fitting within 100 columns. JSON Schema uses `$defs`/`allOf` for rule base type inheritance. Config version bumped from 5 to 6.
