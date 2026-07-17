---
# 76y-6lo
title: Bump swift-syntax to pick up full-parse bulk-intern perf fix (#3384)
status: deferred
type: task
priority: normal
created_at: 2026-07-17T17:47:39Z
updated_at: 2026-07-17T18:00:11Z
sync:
    github:
        issue_number: "755"
        synced_at: "2026-07-17T18:05:04Z"
---

Upstream swiftlang/swift-syntax merged PR #3384 (SHAs 1f6c623, 1b5cd99; rintaro).

## Upstream change
A prior change interned each parsed token's text individually (good for incremental-reparse memory, bad for full-parse performance — one bump-allocation + memcpy per token instead of a single bulk copy). #3384 restores single bulk copy for full (non-incremental) parses: the whole source is copied into the arena once via `ParsingRawSyntaxArena.internSourceBuffer`, and the parser lexes over that copy. `internParsedTokenText` returns in-copy text unchanged. Incremental reparse still interns per re-lexed token.

Files: `Sources/SwiftParser/Parser.swift`, `Sources/SwiftSyntax/Raw/RawSyntaxArena.swift`.

## Task
This is a transparent internal perf improvement — no API surface change, nothing to port. Since Swiftiomatic does full (non-incremental) parses on every lint/format invocation, it benefits directly.
- [ ] On the next routine swift-syntax dependency bump, pull in a revision at or past 1b5cd99.
- [ ] No code changes required; close once the Package.resolved pin includes the fix.

Reference: `~/Developer/swiftiomatic-ref/swift-format` / swift-syntax upstream.

## Deferral Notes

The perf fix (`1b5cd99`) is **not present in any released swift-syntax tag** and cannot be pulled without changing Swiftiomatic's pinning strategy.

Findings (verified 2026-07-17 via `gh api`):
- Current pin: `Package.swift` → `.package(url: swift-syntax, exact: "603.0.1")`; `Package.resolved` at `9de99a7`.
- `1b5cd99` is the current HEAD of swift-syntax `main` (the #3384 merge) — i.e. unreleased/future.
- Newest released tag is `603.0.2` (`79e4b74`). GitHub compare `1b5cd99...603.0.2` → **diverged** (behind 265, ahead 13); the fix is on `main`, not on the 6.x release line.
- Confirmed the fix subject ("Intern the whole source buffer for a full parse") was **not** back-ported into `603.0.2` history.

Why deferred rather than done now:
- Pulling the fix today means either (a) `exact:`-pinning an unstable `main` SHA — abandoning the released-tag strategy and dragging in ~265 unrelated main-only commits, or (b) a `branch: "main"` pin — non-reproducible. Neither is warranted for a transparent, internal perf improvement with no API or behavioral impact.

Resolution / resume condition:
- Wait for a released swift-syntax tag (a `603.0.x` back-port or the next major that branches from post-`1b5cd99` main) that contains the fix, then bump `exact:` to it as a routine dependency update and confirm `Package.resolved` includes the commit.
- Note: `603.0.2` is available as an unrelated routine patch bump, but it does **not** carry this fix, so it doesn't close this issue.
