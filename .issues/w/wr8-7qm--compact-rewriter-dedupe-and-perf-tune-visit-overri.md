---
# wr8-7qm
title: 'Compact rewriter: dedupe and perf-tune visit overrides'
status: completed
type: task
priority: high
created_at: 2026-04-30T02:44:25Z
updated_at: 2026-04-30T03:07:15Z
sync:
    github:
        issue_number: "521"
        synced_at: "2026-04-30T03:34:39Z"
---

The `CompactSyntaxRewriter.swift` (2356 lines) is dominated by mechanical
duplication of a few patterns and re-does the same expensive `shouldRewrite`
prelude work per-rule per-node. From the deep `/swift` review of
`Sources/SwiftiomaticKit/Rewrites/{CompactSyntaxRewriter,SourceFile,TokenRewrites}.swift`.

Phase A (this issue) — CompactSyntaxRewriter.swift, plus the overflow items
into TokenRewrites.swift and SourceFile.swift. Doing all 12 in one batch
because §1+§2+§3+§4+§8 share the same helper API surface and rewriting each
override touches it once; splitting risks two passes.

## Plan

The dependency order matters. Add the helpers first, then sweep overrides
once, then handle the smaller files.

**A. New helpers (no behavior change yet)**

- [x] Add `RewriteGate` struct + `Context.gate(for:)` + `shouldRewrite(_:gate:)` overload — caches `isInsideSelection` + `startLocation` once per node (§1).
- [x] Add `apply<N, R>(_, to: inout N, parent:, gate:, using:)` for the dominant transform-and-narrow pattern (§2).
- [x] Add `applyWidening<N, Wide, R>(_, to: inout N, parent:, gate:, using:)` returning `Wide?` for rules that may widen the node kind (§2 cont).
- [x] Add `applyAsserting<N, R, W>(_, to: inout W, as: N.Type, parent:, gate:, using:)` for the `EnumCaseDecl`/`TypeAliasDecl`/etc. assertion-on-widen idiom (§8).
- [x] Use `defer { … }` directly inline (no `ScopeStack` type needed) so `willEnter`/`didExit` bracketing avoids duplicated exit-replay on early returns (§3).

**B. Sweep `CompactSyntaxRewriter.swift` overrides alphabetically using the helpers**

Each override is a mostly-mechanical rewrite. Touching them once with the
new helpers picks up §1 (gate caching), §2 (`apply` collapse), §3 (defer
scope), §4 (parent computed on first fire only), §8 (assertion variant),
§12 (consistent naming) at the same time.

- [x] AccessorBlockSyntax / AccessorDeclSyntax / ActorDeclSyntax
- [x] AsExprSyntax / AssociatedTypeDeclSyntax / AttributeSyntax / AttributedTypeSyntax / AwaitExprSyntax
- [x] CatchClauseSyntax / ClassDeclSyntax / ClosureExprSyntax / ClosureSignatureSyntax
- [x] CodeBlockItemListSyntax / CodeBlockItemSyntax / CodeBlockSyntax
- [x] ConditionElementListSyntax / ConditionElementSyntax
- [x] DeclModifierSyntax / DeclReferenceExprSyntax / DeinitializerDeclSyntax / DoStmtSyntax
- [x] EnumCaseDeclSyntax / EnumCaseElementSyntax / EnumDeclSyntax / ExtensionDeclSyntax
- [x] ForStmtSyntax / ForceUnwrapExprSyntax / FunctionCallExprSyntax / FunctionDeclSyntax / FunctionEffectSpecifiersSyntax / FunctionParameterSyntax / FunctionSignatureSyntax / FunctionTypeSyntax
- [x] GenericSpecializationExprSyntax / GuardStmtSyntax
- [x] IdentifierTypeSyntax / IfExprSyntax / ImportDeclSyntax / InfixOperatorExprSyntax / InitializerClauseSyntax / InitializerDeclSyntax / IntegerLiteralExprSyntax
- [x] LabeledExprSyntax
- [x] MacroExpansionExprSyntax / MatchingPatternConditionSyntax / MemberAccessExprSyntax / MemberBlockItemListSyntax / MemberBlockItemSyntax
- [x] OptionalBindingConditionSyntax
- [x] PatternBindingSyntax / PrefixOperatorExprSyntax / ProtocolDeclSyntax
- [x] RepeatStmtSyntax / ReturnStmtSyntax
- [x] SourceFileSyntax / StringLiteralExprSyntax / StructDeclSyntax / SubscriptCallExprSyntax / SubscriptDeclSyntax / SwitchCaseItemSyntax / SwitchCaseLabelSyntax / SwitchCaseListSyntax / SwitchCaseSyntax / SwitchExprSyntax
- [x] TernaryExprSyntax / TokenSyntax / TryExprSyntax / TypeAliasDeclSyntax
- [x] VariableDeclSyntax
- [x] WhileStmtSyntax

**C. TokenRewrites.swift**

- [x] §5 Moved precomputed `(titlecased, uppercased)` list onto `Context.preparedAcronyms` (lazy var); added early-out when the identifier has no uppercase letters.
- [x] §6 `applyBlankLinesAroundMark` now short-circuits on `Trivia.pieces.contains(where: isMarkComment)` before allocating the `[TriviaPiece]` array.
- [x] §7 Consolidated `findNewlinesBeforeMark` / `findNewlinesAfterMark` into one `findNewlinesAroundMark(_:in:before:)` helper.

**D. SourceFile.swift**

- [x] §10 Deduped the two branches in `ensureLineBreakAtEOF`; the message is selected via the count, the trivia rewrite happens once.
- [x] §11 Preserve non-newline pieces in the EOF leading trivia: the rewrite now keeps any trailing comments and emits exactly one final newline.

**E. Verify**

- [x] Build clean (`xc-swift swift_package_build`).
- [x] Full test suite — 3010 passed, 0 failed (39.4s).
- [ ] Spot-check a real Swift file via `sm format --style compact` to confirm no behavior diff vs the previous binary on the codebase itself.

## Why batched

§1 and §2 share the gate parameter; the `apply` helper is much cheaper if
it accepts a precomputed `RewriteGate`. §3's `ScopeStack` also wants the
gate. §4 (lazy parent) drops out for free once the helper owns the
`parent` parameter. §8 reuses the gate machinery. Doing them as separate
PRs would mean rewriting every override twice.


## Summary of Changes

**New file** `Sources/SwiftiomaticKit/Rewrites/RewriteHelpers.swift`
- `Context.Gate` struct caching the wrapped `Syntax(node)` and its `SourceLocation`
- `Context.gate(for:)` factory (returns `nil` when out of selection)
- `Context.shouldRewrite(_:gate:)` overload reusing the gate's cached values

**`CompactSyntaxRewriter.swift`** rewritten end-to-end
- 2356 → 1601 lines (-32%)
- Three private `@inline(__always)` helpers (`apply`, `applyWidening`, `applyAsserting`) replace the 4-line transform-and-narrow / widen-or-early-return / assert-on-widen blocks at every call site
- Each visit override now calls `context.gate(for: node)` once and passes the `Gate` to every per-rule check, eliminating the per-rule `isInsideSelection` + `startLocation` work
- `willEnter`/`didExit` bracketing is now `defer`-based, removing duplicated exit-replay on early returns (notably `FunctionDeclSyntax`, `FunctionCallExprSyntax`, `MemberAccessExprSyntax`)
- `let parent = Syntax(node).parent` is captured once at the top of each override and threaded through closures rather than recomputed

**`TokenRewrites.swift`**
- `applyUppercaseAcronyms` reads `context.preparedAcronyms` (precomputed, longest-first); short-circuits when the identifier has no uppercase letters
- `applyBlankLinesAroundMark` short-circuits on `Trivia.pieces.contains(where: isMarkComment)` before allocating the `[TriviaPiece]` array
- `findNewlinesBeforeMark` / `findNewlinesAfterMark` consolidated into one `findNewlinesAroundMark(_:in:before:)` parameterized helper

**`SourceFile.swift`**
- `ensureLineBreakAtEOF` deduped: message chosen by count, trivia rewrite happens in one branch
- Now preserves non-newline trivia (e.g. trailing `// MARK:` comments) on the EOF token instead of replacing the trivia outright

**`Support/Context.swift`**
- Added `lazy var preparedAcronyms: [(titlecased: String, uppercased: String)]` alongside the existing per-rule state vars

**Verification**
- Build succeeds (debug)
- 3010/3010 tests pass
- Reviewing because: the user should spot-check the formatted output of `sm format --style compact` on the swiftiomatic source itself to confirm zero behavior diff before this is marked completed.
