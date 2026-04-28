---
# ddi-wtv
title: Cut over to `compact` pipeline; delete superseded rule files
status: in-progress
type: feature
priority: high
created_at: 2026-04-28T01:41:38Z
updated_at: 2026-04-28T02:41:45Z
parent: iv7-r5g
blocked_by:
    - eti-yt2
    - o72-vx7
    - e4v-075
sync:
    github:
        issue_number: "480"
        synced_at: "2026-04-28T02:56:05Z"
---

## Goal

Replace `FormatPipeline` with the two-stage style-driven architecture from epic `iv7-r5g` and delete the now-orphaned `SyntaxFormatRule` files.

## Stages

1. **Combined `SyntaxRewriter`** — every node-local normalization the `compact` style requires, applied in a single tree walk (validated by spike `eti-yt2`).
2. **Structural passes** (≤3) — `SortImports`, blank-line policy, `ExtensionAccessLevel`-style cross-tree reshapers. Each is its own walk; cross-pass ordering kept explicit.
3. **Pretty-print** — unchanged, parameterised by the style.

## Tasks

- Delete `SyntaxFormatRule` files in the `deletable` bucket of inventory `kl0-8b8`.
- Move surviving rules' logic into the combined rewriter or one of the structural passes; delete the rule files once their logic is absorbed.
- Regenerate `Sources/SwiftiomaticKit/Generated/Pipelines+Generated.swift` — the lint section is unchanged, the rewrite section either disappears or shrinks to the structural passes.
- Update `Sources/Generator/` to reflect the new architecture if needed.
- Run the full lint + layout test suite. Run `Tests/SwiftiomaticPerformanceTests/RewriteCoordinatorPerformanceTests.swift` and confirm < 200 ms on `LayoutCoordinator.swift`.

## Verification

- `xc-swift swift_package_test` clean.
- `sm format Sources/SwiftiomaticKit/Layout/LayoutCoordinator.swift` finishes well under 200 ms.
- Diff of formatted output across the project is empty (or only contains intentional changes documented in the `compact` spec).



## Refinement: keep file organization

The combined stage-1 rewriter is a **thin dispatcher**, not a megafile. Each `visit(_:)` override delegates to a free function or extension method living in its own file under `Sources/SwiftiomaticKit/Rules/<Group>/<Aspect>.swift` — preserving today's discoverability. The directory layout under `Rules/` should look familiar after cutover; only the type-level wrapping (`SyntaxFormatRule` subclass + own `SyntaxRewriter` per rule) goes away. Performance stays the primary goal; file structure is a secondary nice-to-have.



## Execution Playbook (for follow-up session)

The spike (`eti-yt2`) confirmed ~900× headroom on the worst-case file. The blocking issue for an in-session cutover is **double-recursion**: today's rules subclass `SyntaxRewriter` and their `visit(_ T)` calls `super.visit(node)` first (recursing children), then applies single-node logic. A combined rewriter that simply chained each rule's `visit` per node would re-recurse children N times — worse than today.

### Required refactor (one-time, mechanical)

For each of the 122 node-local rules, extract the single-node logic into a static `transform` function:

```swift
// Before (today)
final class ACLConsistency: RewriteSyntaxRule<BasicRuleValue> {
    override func visit(_ node: DeclModifierSyntax) -> DeclModifierSyntax {
        let visited = super.visit(node)  // recurses
        // ... single-node logic
    }
}

// After
enum ACLConsistencyTransform {
    static func transform(
        _ node: DeclModifierSyntax,
        context: Context
    ) -> DeclModifierSyntax {
        // ... single-node logic only (no super.visit)
    }
}
```

### Cutover steps (in order)

1. **Generator extension** (`Sources/GeneratorKit/PipelineGenerator.swift`):
   - Collect node-type → [transform-fn] mapping for the 122 node-local rules (parallel to `syntaxNodeLinters`).
   - Emit a new `CompactStageOneRewriter+Generated.swift` whose `visit(_ T)` calls `super.visit(node)` once, then chains every rule's static `transform` for that node type.

2. **Rule refactor** (122 files): extract static `transform` functions. Mechanical; can be done rule-by-rule without breaking the existing pipeline (additive).

3. **Wire compact path** (`RewriteCoordinator`):
   - When `config[StyleSetting.self] == .compact`: run `CompactStageOneRewriter` (one walk), then the 13 structural passes from `kl0-8b8` in the order from `2kl-d04` §2.
   - Keep the legacy `RewritePipeline` as a fallback (initially gated on a debug flag, removed in a follow-up).

4. **Structural passes**: keep the 13 structural rules from `kl0-8b8` as ordered `SyntaxRewriter` subclasses. Order from `2kl-d04`: SortImports → BlankLinesAfterImports → FileScopedDeclarationPrivacy → ExtensionAccessLevel → PreferFinalClasses → ConvertRegularCommentToDocC → BlankLinesBetweenScopes → ConsistentSwitchCaseSpacing → SortDeclarations → SortSwitchCases → SortTypeAliases → FileHeader → ReflowComments.

5. **Delete** the 122 `RewriteSyntaxRule` subclass shells once their transform fns are absorbed and tests pass. Lint-side rules continue using the same files (some are dual lint+rewrite — split into separate types if needed).

6. **Regenerate** `schema.json`: `swift run Generator`.

7. **Verify**:
   - `xc-swift swift_package_test` clean.
   - `testCombinedRewriterOnLayoutCoordinator` perf < 200 ms (currently 5 ms with 3 rules; expect ~50–150 ms with all 122).
   - Diff `sm format` output across the project — should be empty or only intentional changes documented in `2kl-d04` §7.

### Risk mitigations

- **Same-node-type conflicts**: when multiple rules transform the same node type, order matters. The Generator should emit them in a deterministic order (alphabetical or explicit priority list per node type). Add a test for any known interactions.
- **Rule logic that reads parent**: a few node-local rules (e.g. `ACLConsistency` walking up to nominal parent) read `node.parent`. Within a single walk, the parent is the *original* tree's parent until `super.visit` returns — same constraint today's rules navigate. Should still work; flag during cutover if not.
- **Diagnostics**: today each rule's `diagnose()` calls go through `context`. The static `transform` functions need `context` passed in. Trivial.

### Estimated effort

- Generator extension + scaffolding: ~half day.
- Rule refactor (122 files, ~5 min each): ~2–3 days.
- Wire-up + structural pass ordering: ~half day.
- Test diff resolution: ~1 day.

Total: ~4–5 days of focused work.
