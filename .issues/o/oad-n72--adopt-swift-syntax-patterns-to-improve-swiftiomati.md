---
# oad-n72
title: Adopt swift-syntax patterns to improve Swiftiomatic
status: completed
type: epic
priority: normal
created_at: 2026-04-12T23:53:37Z
updated_at: 2026-04-13T00:51:22Z
sync:
    github:
        issue_number: "239"
        synced_at: "2026-04-13T00:55:41Z"
---

Insights from reviewing the swift-syntax source at `~/Developer/apple/swift-syntax` that could improve Swiftiomatic's correction pipeline, diagnostic model, formatting infrastructure, and IDE performance.

Reference: cited in `.jig.yaml` under `citations:` — `swiftlang/swift-syntax` (main branch).

## Not Pursued

**Arena allocation** — swift-syntax's `BumpPtrAllocator` and `RawSyntaxArena` are internal parser optimizations. Our caching at the `SwiftSource` level achieves similar benefits at a higher layer.

**Custom Traits** — Protocol-based uniform access (e.g., `.introducer` on all declaration types) could reduce some pattern matching in rules, but our visitor pattern already dispatches by node type effectively.



## Summary of Changes

All 7 child issues completed:

### Implemented
1. **se8-7qh** — AST-level `FixIt.Change` variants for `SyntaxViolation.Correction` (4 enum cases: textReplacement, replaceNode, replaceLeadingTrivia, replaceTrailingTrivia)
2. **zwz-qaz** — Conflict-aware `CorrectionApplicator` ported from swift-syntax `FixItApplier` (8 unit tests)
3. **y8r-1uz** — Diagnostic highlights and notes propagated through full pipeline (SyntaxViolation → RuleViolation → Diagnostic JSON)
4. **ftl-21i** — `RuleCategory` hierarchy auto-derived from directory structure via `GeneratePipeline` (337 rules categorized)
5. **gxn-fyv** — Incremental parsing infrastructure (`reparseIncrementally` + `IncrementalParseResult` cache)

### Evaluated and Passed
6. **urw-dxb** — BasicFormat token-pair abstraction: pass (our two-layer swift-format + per-rule lint is better)
7. **s2x-yjv** — SwiftSyntaxBuilder result builders: pass (our .with() + Correction enum covers the space)
