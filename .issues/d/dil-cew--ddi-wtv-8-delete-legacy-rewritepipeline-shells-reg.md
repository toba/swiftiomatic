---
# dil-cew
title: 'ddi-wtv-8: delete legacy RewritePipeline shells; regen schema'
status: completed
type: task
priority: normal
created_at: 2026-04-28T02:43:08Z
updated_at: 2026-04-29T18:01:08Z
parent: ddi-wtv
blocked_by:
    - g6t-gcm
    - fkt-mgf
    - 7fp-ghy
sync:
    github:
        issue_number: "487"
        synced_at: "2026-04-29T22:39:24Z"
---

After verification (ddi-wtv-7) passes, remove the legacy code path.

## Tasks

- [x] Delete the `extension RewritePipeline { func rewrite(_:) }` block from PipelineGenerator (rewrite section) — landed in `dal-dmw` (commit 92672ce4-area).
- [x] Delete the now-unused `visit(_:)` overrides on each rule that's been ported to `static transform` — substantially completed across `dal-dmw` sessions 2–22. Remaining `override func visit` are on lint rules (`SyntaxLintRule`, out of scope), structural-pass rules (out of scope), and `PreferShorthandTypeNames` (kept by design — recursion is fundamental).
- [x] Regenerate `schema.json` via the Generator executable.
- [x] `Configuration` per-rule rewrite/lint matrix — verified still required. `SyntaxRuleValue` (`rewrite: Bool` + `lint: Lint`) is the source of truth for both rewrite-mode gating (`Context.shouldFormat` → `Configuration.isActive`) and lint severity (`Context.severity`). Not removable.
- [x] Final test pass: 3012 pass / 2 pre-existing GuardStmt failures.

## Done when

Legacy `RewritePipeline.rewrite` code path is gone; only the compact path exists; tests green; `schema.json` regenerated.



## Summary of Changes

Most scope absorbed into `dal-dmw`. Remaining work:

- Ran `swift run Generator` to regenerate `schema.json`. Diff: ~96 insertions / 76 deletions, mostly cosmetic (spaces around inline-code backticks in rule descriptions, picked up from already-reformatted source doc comments) plus a few structural additions (e.g. compact/roomy style enum, switch-case-indentation flush/indented enum).

### Verification

- `xc-swift swift_diagnostics --no-include-lint`: build clean (13 warnings).
- `xc-swift swift_package_test`: 3012 pass / 2 pre-existing failures.
