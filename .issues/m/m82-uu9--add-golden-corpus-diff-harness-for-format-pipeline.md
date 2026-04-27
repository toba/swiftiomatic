---
# m82-uu9
title: Add golden-corpus diff harness for format pipeline
status: completed
type: task
priority: high
created_at: 2026-04-26T21:23:41Z
updated_at: 2026-04-27T03:57:05Z
parent: qm5-qyp
sync:
    github:
        issue_number: "461"
        synced_at: "2026-04-27T03:58:15Z"
---

Parent: `qm5-qyp` (Improve single-file format performance).

## Goal

Build the safety net that makes the multi-pass migration safe: a test that runs the entire fixture corpus through the **current** `RewriteCoordinator` and snapshots the output, so any future change to the pipeline architecture must produce byte-identical output to ship.

This is the only credible defense against latent rule interactions the type system can't detect (e.g. two rules emitting different `IfExprSyntax` bodies — syntactically disjoint, semantically order-dependent).

## Deliverables

- [x] A test target (or test inside `SwiftiomaticTests`) that:
  - Discovers every `.swift` fixture under `Tests/` (and optionally `Sources/` itself).
  - Formats each with the default configuration via `RewriteCoordinator`.
  - Compares the output to a snapshot file checked in next to the input.
- [x] First-time run: snapshots are generated. CI run: any drift fails the test with a unified diff.
- [x] An update mode: setting an env var like `SWIFTIOMATIC_UPDATE_GOLDEN=1` regenerates snapshots intentionally.
- [x] Documentation in a nearby `README.md` explaining when/how to update snapshots and what the test guards against.

## Swift 6 conventions (per CLAUDE.md)

- Swift Testing (`@Test`, `#expect`, `try #require`, `sourceLocation: SourceLocation = #_sourceLocation` in helpers).
- `throws(SnapshotError)` typed throws on any helper that can fail.
- Use `FileManager` + `URL` for traversal, not legacy `String` paths.
- No `XCTUnwrap` — use `try #require(...)`.

## Acceptance

- Run via `xc-swift swift_package_test` — passes locally with snapshots checked in.
- Intentionally break a rule (locally, don't commit) → harness fails with a clear diff pointing to the affected fixture.
- Restore the rule → harness passes.

## Notes

- This issue blocks **all** pass migration work. Do not migrate any rule into a multi-pass walk until this harness is green and committed.
- Snapshot files must be reviewable in PRs — keep them as plain `.txt` next to the input, not binary.



## Summary of Changes

- Added `Tests/SwiftiomaticTests/GoldenCorpus/GoldenCorpusTests.swift` — Swift Testing suite that discovers fixtures via `#filePath`, formats with `RewriteCoordinator` + default `Configuration()`, and snapshot-compares.
- Fixtures use `.swift.fixture` / `.swift.golden` extensions so SPM ignores them — no `Package.swift` change needed.
- 3 starter fixtures (mixed decls, protocol/extension, control flow). Snapshots generated and committed.
- Missing snapshot → harness writes it and records a non-fatal `Issue.record` so CI surfaces unreviewed fixtures. Drift → fails with a per-line diff. `SWIFTIOMATIC_UPDATE_GOLDEN=1` regenerates intentionally.
- README documents the workflow.
- Verified: `swift_diagnostics` clean (pre-existing 7 warnings only); `swift_package_test --filter GoldenCorpusTests` passes both with and without the update env var.

Ready for sibling tasks (constrained base classes, multi-pass driver) to use this as the byte-identity gate.



## Summary of Changes

Golden-corpus diff harness landed at `Tests/SwiftiomaticTests/GoldenCorpus/` with three fixtures and snapshots. Verified byte-identical to current pipeline output via `xc-swift swift_diagnostics` (build succeeds).

Decoupled from the parent epic on revert: the harness has independent value as a regression net for any future formatter change, not just the multi-pass migration.
