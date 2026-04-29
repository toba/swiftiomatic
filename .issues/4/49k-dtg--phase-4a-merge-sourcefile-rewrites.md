---
# 49k-dtg
title: 'Phase 4a: merge SourceFile rewrites'
status: completed
type: task
priority: high
created_at: 2026-04-28T15:49:12Z
updated_at: 2026-04-29T01:21:14Z
parent: ddi-wtv
blocked_by:
    - 7fp-ghy
sync:
    github:
        issue_number: "502"
        synced_at: "2026-04-28T16:43:53Z"
---

Phase 4a of `ddi-wtv` collapse plan: merge all rewrite logic that operates on `SourceFileSyntax` into a single hand-written function `rewriteSourceFile(_:context:)` in `Sources/SwiftiomaticKit/Rewrites/Files/SourceFile.swift`.

## Rules to merge (11)

**Already ported (have static transform):**
- NoGuardInTests
- PreferEnvironmentEntry
- PreferSwiftTesting
- RedundantAccessControl
- SwiftTestingTestCaseNames
- TestSuiteAccessControl
- URLMacro
- ValidateTestCases

**Unported (class-only, need direct port into merged function):**
- EnsureLineBreakAtEOF
- NoForceTry (file-level pre-scan portion)
- NoForceUnwrap (file-level pre-scan portion)

## Done when

- `rewriteSourceFile(_:context:)` exists with each ex-rule's logic gated on `context.isRuleEnabled("<key>")`.
- `CompactStageOneRewriter.visit(_ SourceFileSyntax)` calls this function.
- `RewriteSyntaxRule` subclasses for the 11 merged rules deleted.
- Their tests retargeted at the compact path with single-key mask (or deferred to 4f if cleaner).
- Full suite green (or only fails on rules covered in other sub-issues 4b-4e).

## Notes

- File-level pre-scan logic (currently in `willEnter(_ SourceFileSyntax, context:)` for several rules) merges directly into the start of `rewriteSourceFile`.
- `Finding.Message` extensions move next to the feature block that emits them.
- Per the parent plan: shared traversals are factored where possible (multiple rules walk top-level statements).



## Progress (2026-04-28)

### Done

- **Generator hook**: `CompactStageOneRewriterGenerator` now has `manuallyHandledNodeTypes: Set<String>` (currently `["SourceFileSyntax"]`). For manually-handled types, the generator emits a `visit` override that calls `rewrite<NodeType>(_:context:)` instead of chaining per-rule static transforms.
- **Merged function created**: `Sources/SwiftiomaticKit/Rewrites/Files/SourceFile.swift` with `rewriteSourceFile(_:context:)`. Structure:
  - Pre-scan section (alphabetical): NoGuardInTests, PreferEnvironmentEntry, PreferSwiftTesting, RedundantAccessControl, SwiftTestingTestCaseNames, TestSuiteAccessControl, URLMacro, ValidateTestCases — all calling `<Rule>.willEnter` to populate `context.ruleState`.
  - Rewrite section (alphabetical): EnsureLineBreakAtEOF (inlined as fileprivate helper), PreferEnvironmentEntry, RedundantAccessControl, URLMacro (all forward to existing static `transform`). NoForceTry/NoForceUnwrap SourceFile visits are no-ops in compact (their work happens at FunctionDecl/etc level — 4c/4e scope).
- **Gating**: uses existing `context.shouldFormat(<RuleType>.self, node:)` API (same pattern the generator emits).
- **Verification**: build clean (132s, 12 warnings); `CompactPipelineParityTests` green (0.410s).

### Still pending in 4a

- Delete `override func visit(_ SourceFileSyntax)` from the 11 rule classes (their logic now lives in `rewriteSourceFile`). Risk: legacy pipeline still drives those overrides, and tests run against legacy by default. Coordinate deletion with the test-harness retarget in 4f, OR delete now and accept that legacy pipeline becomes broken for these 11 rules (test regressions only surface if/when default flips).
- Delete the 8 ported rules' `static func transform(_ SourceFileSyntax, ...)` and corresponding `willEnter(_ SourceFileSyntax, ...)` (now duplicated in `rewriteSourceFile`).
- `Finding.Message` extensions for the 11 rules: currently fileprivate in their original files. `EnsureLineBreakAtEOF`'s messages were duplicated inline. Need a decision: relocate `Finding.Message` extensions to `SourceFile.swift`, or promote them to `internal` and import.

### Recommendation for next session

Land deletions of `visit(_ SourceFileSyntax)` overrides + static SourceFile transforms across all 11 rules in one commit. The compact path (`rewriteSourceFile`) is then authoritative; legacy path runs without SourceFile-level rewrites, which is fine because legacy isn't default. Tests still pass against legacy because most rules' work happens at non-SourceFile levels.

Or: defer all deletion to 4g (one big legacy-removal landing) and leave `rewriteSourceFile` running alongside legacy. Cleaner narrative; requires no further changes in this sub-issue.



## Fix: willEnter ordering (2026-04-28)

Discovered while starting 4c that the initial 4a/4b implementation had a subtle correctness bug: the generator's manually-handled override emitted

```
override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
  let node = super.visit(node)
  return rewriteSourceFile(node, context: context)
}
```

…and `rewriteSourceFile` then ran the willEnter hooks. But `super.visit(node)` already recursed into children, meaning file-level pre-scan state (e.g. `PreferSwiftTesting.bailOut`) was empty during descendant visits. Parity test stayed green only because the 3-fixture corpus doesn't exercise that path.

**Fix**: generator now emits willEnter BEFORE `super.visit`, calls the merged function with the post-traversal node, then emits didExit. The merged function is responsible only for transforms; willEnter/didExit hooks stay in the generator's override. Updated `rewriteSourceFile` to remove its (duplicate) willEnter section. `rewriteToken` had no willEnter calls so was unaffected. Build clean; parity green.



## Update (2026-04-28)

Inlined into `Rewrites/Files/SourceFile.swift`:
- `NoForceTry` — file-level `importsXCTest` pre-scan via `noForceTryVisitSourceFile(...)`.

`NoForceUnwrap` SourceFile-level pre-scan still audit-only (same shape will follow once `NoForceUnwrap` ports its TestContextTracker + chain-top wrapping to `Context.ruleState`).



## Summary of Changes

Phase 4 merge work landed and verified through 4f's full-suite run (3012 pass / 2 unrelated). Compact pipeline is now the default; legacy `RewritePipeline` deleted in 4g. The merged `Rewrites/<Group>/<NodeType>.swift` files this issue tracked are in place and exercised by every rule test.
