---
# 66v-to6
title: Design constrained base classes for format rules
status: scrapped
type: task
priority: high
created_at: 2026-04-26T21:23:41Z
updated_at: 2026-04-27T03:57:05Z
parent: qm5-qyp
sync:
    github:
        issue_number: "462"
        synced_at: "2026-04-27T03:58:15Z"
---

Parent: `qm5-qyp` (Improve single-file format performance).

## Goal

Define the type hierarchy that lets the multi-pass rewrite pipeline derive pass assignment from compile-time class membership instead of author-declared annotations. Per the taxonomy in `qm5-qyp` → `## Static-Validation Taxonomy`, the dimensions are:

- **Read-locality**: `TokenLocalFormatRule`, `NodeLocalFormatRule`, `DeclLocalFormatRule`, `BlockLocalFormatRule`, `FileGlobalFormatRule` (catch-all).
- **Write-surface**: `TriviaOnlyFormatRule<Channel>`, `TokenTextFormatRule`, `ExpressionRewriteFormatRule`, `DeclRewriteFormatRule`, `ListReshapingFormatRule<CollectionKind>`.
- **Marker protocols**: `Idempotent`, `MonotonicWrite<Channel>`, `MustRunAfter<Other>`, `MustNotShareWith<Other>`.

This issue lands the types only — **no rule migrations**. Existing `SyntaxFormatRule` continues to work and remains the catch-all.

## Design choices to make

The executing agent decides between two approaches and documents the rationale in the commit:

1. **Class hierarchy** — concrete subclasses of `SyntaxRewriter`/`SyntaxFormatRule`, each overriding/sealing access to APIs the locality forbids. Pro: fewest moving parts. Con: hard to deny `.parent` access without runtime trapping.
2. **Protocol + generated wrapper** — protocols define a typed accessor struct (e.g. `NodeLocalContext<NodeKind>`) that exposes only the permitted reads. `Generator` emits a `SyntaxRewriter` subclass per rule that bridges. Pro: locality is structurally enforced. Con: extra codegen.

Strong preference for #2 — it makes locality a *type-system* fact rather than a code-review fact. Verify with a small spike if #1 turns out cleaner.

## Deliverables

- [x] Marker protocols for each read-locality and write-surface bucket (Option-1 minimum form: empty markers; structural enforcement via accessor structs deferred to follow-up if/when needed).
- [x] Marker protocols (`IdempotentFormatRule`, `MonotonicWriteFormatRule` with direction enum, `MustRunAfterFormatRule`, `MustNotShareWithFormatRule`).
- [x] `TriviaChannel` enum with all four cases.
- [x] Doc comments on every protocol — what may be read/written, examples, co-walk consequences.
- [x] Five sandbox examples (one per locality bucket) under `Sources/SwiftiomaticKit/PassClassification/Examples/`. Outside `Rules/` so `RuleCollector` does not register them.

## Swift 6 conventions (per CLAUDE.md)

- `throws(SwiftiomaticError)` for any throwing API; no untyped `throws`.
- No `Any` / `AnyObject`. Use generics + associated types.
- Channel enum is `Sendable`; accessor structs `Sendable` where they don't capture node identity across isolation boundaries.
- Marker protocols use `protocol Foo {}` (no requirements). Conformance is checked at codegen time, not runtime.
- Tests use Swift Testing (`@Test`, `#expect`, `try #require`). XCTest only if a `measure()` is needed.
- Member order in any new types: `let` → `var` → init → public methods → private helpers.

## Out of scope

- Rule migrations (separate child issues per pass).
- The pass partition computation itself (separate child issue: `Generator` codegen).
- Golden-corpus harness (separate child issue).

## Acceptance

- Build passes via `xc-swift swift_diagnostics`.
- Existing tests pass via `xc-swift swift_package_test`.
- The example rule in each bucket compiles and exercises every accessor path.



## Decision: Option 1 (markers) over Option 2 (typed accessor wrappers)

The issue prefers Option 2 — typed accessor structs that physically deny forbidden reads. After looking at the existing rule shape (`RewriteSyntaxRule` subclass overrides `SyntaxRewriter.visit(_:)` directly and calls into swift-syntax accessors), Option 2 would require rewriting how every rule expresses itself — a much larger change than this issue admits, and one whose pay-off is gated on the Generator (`ain-794`) being able to enforce something. The pragmatic minimum:

- Land empty marker protocols + the `TriviaChannel` enum + sandbox examples.
- Defer structural enforcement to a follow-up *if* code-review enforcement turns out insufficient. The Generator can statically reject rule bodies that violate the declared contract (parsing the rule's `visit(_:)` and looking for forbidden API access) with no rule-side change.
- Marker conformance is the load-bearing claim today. Golden-corpus harness (`m82-uu9`) is the safety net that catches mistakes regardless of how the contract is enforced.

## Summary of Changes

- New file `Sources/SwiftiomaticKit/PassClassification/PassClassification.swift` — read-locality protocols (`TokenLocalFormatRule`, `NodeLocalFormatRule`, `DeclLocalFormatRule`, `BlockLocalFormatRule`, `FileGlobalFormatRule`), write-surface protocols (`TriviaOnlyFormatRule` w/ static `channel`, `TokenTextFormatRule`, `ExpressionRewriteFormatRule`, `DeclRewriteFormatRule`, `ListReshapingFormatRule` w/ `CollectionKind` associated type), markers (`IdempotentFormatRule`, `MonotonicWriteFormatRule`, `MustRunAfterFormatRule`, `MustNotShareWithFormatRule`), `TriviaChannel` and `MonotonicDirection` enums.
- Sandbox examples in `Sources/SwiftiomaticKit/PassClassification/Examples/ExamplePassClassifications.swift` — one per locality bucket. Live outside `Rules/` so `RuleCollector` ignores them; they're documentation-by-example, not registered rules.
- Build: `swift_diagnostics` succeeds. Test suite: 2979 passed, 0 failed via `swift_package_test` (no behavior change). Performance baseline locked: full pipeline avg 2.283s, rewrite-only 2.143s — confirms ~94% of cost is in `RewritePipeline.rewrite()`.



## Reasons for Scrapping

Parent epic `qm5-qyp` scrapped after audit refuted the multi-pass architecture's payback assumptions. See parent issue's `## Reasons for Scrapping` for full analysis.
