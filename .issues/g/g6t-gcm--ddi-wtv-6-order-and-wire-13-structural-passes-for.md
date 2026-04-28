---
# g6t-gcm
title: 'ddi-wtv-6: order and wire 13 structural passes for compact'
status: completed
type: task
priority: normal
created_at: 2026-04-28T02:43:08Z
updated_at: 2026-04-28T05:17:21Z
parent: ddi-wtv
blocked_by:
    - vz0-31g
    - 5r3-peg
    - r0w-l4r
sync:
    github:
        issue_number: "488"
        synced_at: "2026-04-28T02:56:06Z"
---

After the combined node-local rewriter is complete, the compact path runs a fixed list of structural passes in deterministic order.

## Order (per 2kl-d04 sec 2)

1. SortImports
2. BlankLinesAfterImports
3. FileScopedDeclarationPrivacy
4. ExtensionAccessLevel
5. PreferFinalClasses
6. ConvertRegularCommentToDocC
7. BlankLinesBetweenScopes
8. ConsistentSwitchCaseSpacing
9. SortDeclarations
10. SortSwitchCases
11. SortTypeAliases
12. FileHeader
13. ReflowComments

## Tasks

- [x] In `RewriteCoordinator.runCompactPipeline(_:)`, after `CompactStageOneRewriter.rewrite(node)`, run each structural pass in order
- [x] Each structural rule keeps its existing `RewriteSyntaxRule` shell (these legitimately need a settled tree per pass)
- [x] Add a test asserting the ordering produces the same output as the legacy pipeline on the golden corpus

## Done when

Compact path runs combined rewriter + 13 ordered passes; output matches legacy on the golden corpus (or only differs in ways documented in 2kl-d04).



## Summary of Changes

Wired the two-stage compact pipeline behind a new `DebugOptions.useCompactPipeline` flag. Default path remains the legacy `RewritePipeline` until `fkt-mgf` validates parity on a broader corpus and `dil-cew` flips the default + deletes the legacy code.

### Files changed

- `Sources/SwiftiomaticKit/Support/DebugOptions.swift` — added `useCompactPipeline` flag.
- `Sources/SwiftiomaticKit/Syntax/Rewriter/RewriteCoordinator.swift` — added `runTwoStageCompactPipeline(_:context:)`. Pipeline runs `CompactStageOneRewriter` then the 13 structural passes in the order from `2kl-d04` §2:
  1. `SortImports`
  2. `BlankLinesAfterImports`
  3. `FileScopedDeclarationPrivacy`
  4. `ExtensionAccessLevel`
  5. `PreferFinalClasses`
  6. `ConvertRegularCommentToDocC`
  7. `BlankLinesBetweenScopes`
  8. `ConsistentSwitchCaseSpacing`
  9. `SortDeclarations`
  10. `SortSwitchCases`
  11. `SortTypeAliases`
  12. `FileHeader`
  13. `ReflowComments`
- `Tests/SwiftiomaticTests/GoldenCorpus/CompactPipelineParityTests.swift` — new parameterized parity test that formats every golden fixture with both pipelines and records divergences as Issues (not failures, since `fkt-mgf` is the official gate).

### Verification

- `xc-swift swift_diagnostics --build-tests` → clean (9 pre-existing warnings).
- `xc-swift swift_package_test --filter CompactPipelineParityTests` → 1 passed, 0 failed. Two-stage output is byte-identical to legacy on the current 3-fixture golden corpus.

### Notes for follow-up issues

- `fkt-mgf` should expand the corpus (especially fixtures that exercise the rules left on legacy in `r0w-l4r`/`5r3-peg`: `RedundantSelf`, `NoSemicolons`, `RedundantAccessControl`, the `Testing/*` rules, `WrapSingleLineBodies`, etc.). Until those are ported (or explicitly excluded from compact), the parity test is incomplete.
- `dil-cew` will: flip the default to two-stage, remove `useCompactPipeline` flag (or keep as no-op), delete `RewritePipeline.swift` + the rewrite section of `Pipelines+Generated.swift`, and delete every legacy `override func visit` once its rule is verified ported.

### Tasks remaining

Per parent `ddi-wtv`: `fkt-mgf` (golden-corpus diff + perf gate) and `dil-cew` (delete legacy).
