---
# vz0-31g
title: 'ddi-wtv-3: extract static transforms (Access + Closures + Conditions clusters)'
status: ready
type: task
priority: normal
created_at: 2026-04-28T02:42:45Z
updated_at: 2026-04-28T02:42:45Z
parent: ddi-wtv
blocked_by:
    - ogx-lb7
sync:
    github:
        issue_number: "493"
        synced_at: "2026-04-28T02:56:06Z"
---

Mechanical refactor: for each `RewriteSyntaxRule` in the listed directories, extract single-node logic into `static func transform(_ node: T, context: Context) -> T`. The existing `visit(_:)` method calls `super.visit(node)` then `Self.transform(visited, context: context)` so the legacy pipeline keeps working.

## Scope

- `Sources/SwiftiomaticKit/Rules/Access/`
- `Sources/SwiftiomaticKit/Rules/Closures/`
- `Sources/SwiftiomaticKit/Rules/Conditions/`

Skip rules that are pure lint (no `RewriteSyntaxRule`). Skip rules already in the structural-pass bucket from `kl0-8b8` (e.g. `FileScopedDeclarationPrivacy`).

## Tasks

- [ ] Inventory the directories; list rule files in scope (use checklist below as you go)
- [ ] For each in-scope rule: extract `transform`, keep `visit` calling it, run rule's existing tests
- [ ] No behavior change; `lintingSyntaxRules` collector still picks them up

## Done when

All in-scope rules expose `static transform`; existing test suite green.
