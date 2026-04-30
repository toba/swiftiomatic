---
# izj-f32
title: PreferTypedThrowsOverResult
status: completed
type: feature
priority: normal
created_at: 2026-04-30T23:00:02Z
updated_at: 2026-04-30T23:05:10Z
parent: 7h4-72k
sync:
    github:
        issue_number: "572"
        synced_at: "2026-04-30T23:13:20Z"
---

Lint a function returning `Result<T, E>` whose body is exactly a single `do { return .success(...) } catch { return .failure(...) }`. Suggest replacing with `throws(E) -> T`.

## Decisions

- Group: `.idioms`
- Default: `.warn`
- Lint-only — rewrite would require updating callers.
- Trigger: a FunctionDecl whose return type is `Result<...>` and whose body is exactly a single DoStmt with one CatchClause; the do-body's last statement returns `.success(...)` and the catch returns `.failure(...)`.

## Plan

- [x] Failing test
- [x] Implement `PreferTypedThrowsOverResult`
- [x] Verify test passes; regenerate schema



## Summary of Changes

- LintSyntaxRule on `FunctionDeclSyntax`. Matches when return type is `Result<...>` and body is exactly a single DoStmt with one CatchClause; do-body's last return is `.success(...)` and catch's last return is `.failure(...)`.
- 5/5 tests passing.
- Schema regenerated.
