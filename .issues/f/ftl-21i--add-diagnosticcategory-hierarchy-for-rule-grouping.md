---
# ftl-21i
title: Add DiagnosticCategory hierarchy for rule grouping
status: ready
type: feature
priority: low
created_at: 2026-04-12T23:54:23Z
updated_at: 2026-04-12T23:54:23Z
parent: oad-n72
sync:
    github:
        issue_number: "250"
        synced_at: "2026-04-13T00:25:20Z"
---

swift-syntax's `DiagnosticCategory` with `name`, `documentationURL`, and `categoryChain` (leaf-to-root) could enable category-level filtering beyond per-rule enable/disable.

## Reference

`SwiftDiagnostics/Message.swift`:
- `DiagnosticCategory` struct: `name: String`, `documentationURL: String?`
- `DiagnosticMessage.categoryChain: [DiagnosticCategory]` — leaf-first hierarchy

## Mapping to Swiftiomatic

Rule directory structure already implies categories (Redundancy, Performance, Style, Concurrency, etc.). This would formalize them as filterable metadata.

## Tasks

- [ ] Define category hierarchy matching existing rule directory structure
- [ ] Add `category` static property to `Rule` protocol (or derive from directory/module)
- [ ] Add `documentationURL` support for generated docs
- [ ] Support `--category` / `--exclude-category` CLI flags
- [ ] Support category-level enable/disable in `.swiftiomatic.yaml`
