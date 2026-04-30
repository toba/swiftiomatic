---
# uqb-m5z
title: Collapse rewrite pipeline boilerplate; let the generator do the work
status: review
type: task
priority: high
created_at: 2026-04-30T00:20:51Z
updated_at: 2026-04-30T00:44:42Z
sync:
    github:
        issue_number: "510"
        synced_at: "2026-04-30T00:55:14Z"
---

## Summary

The current rewrite layer adds a lot of indirection that pays nothing: per-decl-type wrapper functions in `Sources/SwiftiomaticKit/Rewrites/Decls/*.swift`, the `context.applyRewrite` shim, paired `shouldRewrite` gates around every `willEnter`/`didExit`, and the giant per-decl-type switches inside rules like `RedundantAccessControl`. Reading a single file walk requires three or four function hops and re-derives the same gate ten times. None of it survives a "what does this code actually do?" lens.

The project does not need backward compatibility, configurability, or a future-proof rule abstraction. The end goal is: parse, walk the tree once, mutate, print. Everything else is overhead.

## Concrete pain (with citations)

### 1. `Rewrites/Decls/*.swift` are ~13 hand-typed echoes of generated code

`Sources/SwiftiomaticKit/Rewrites/Decls/FunctionDecl.swift:9-159` is 20 near-identical `context.applyRewrite(Rule.self, to: &result, parent: parent, transform: Rule.transform)` calls — 5 lines per rule, all the same shape. `StructDecl.swift`, `ClassDecl.swift`, `EnumDecl.swift`, `ProtocolDecl.swift`, `ActorDecl.swift`, `VariableDecl.swift` are the same pattern with different rule lists. Same for `Stmts/*.swift` (`CodeBlockItemList.swift:5-71` runs 11 if-let-shouldRewrite blocks in a row).

These files are pure data: "for `FunctionDeclSyntax`, run rules A, B, C, D… in this order." That data already exists inside `RuleCollector` (`Sources/GeneratorKit/RuleCollector.swift`). The build plugin already generates `CompactStageOneRewriter+Generated.swift` from it. The hand-written `Rewrites/Decls/*.swift` files are a second dispatch layer in a slightly different style — pure duplication of intent.

**Action**: delete the `Rewrites/Decls/`, `Rewrites/Exprs/`, `Rewrites/Stmts/` shells. Have the generator emit one `visit(_ node: FunctionDeclSyntax)` body that inlines every rule call. No wrapper function, no `applyRewrite`, no `parent: Syntax?` parameter that just calls `Syntax(node).parent` again.

### 2. `context.applyRewrite` is a four-line shim wrapping a one-line transform call

`Sources/SwiftiomaticKit/Support/Context.swift:140-150`:
```swift
func applyRewrite<R, N, Out>(
    _ rule: R.Type, to node: inout N,
    parent: Syntax? = nil,
    transform: (N, Syntax?, Context) -> Out
) {
    guard shouldRewrite(rule, at: Syntax(node)) else { return }
    if let next = transform(node, parent, self).as(N.self) { node = next }
}
```

Inlined at the call site this is two lines. The generic re-narrowing (`.as(N.self)`) only matters for widening rules — and widening rules already bypass `applyRewrite` and call `transform` directly. So for non-widening rules the `.as(N.self)` is always the identity check.

**Action**: delete `applyRewrite`. Rules return their input type by default; widening rules are special-cased explicitly (already are: see `StaticStructShouldBeEnum` callout in `StructDecl.swift:91`).

### 3. `shouldRewrite` is checked twice for every state-bearing rule

In `CompactStageOneRewriter+Generated.swift:175-220` (the `ClassDeclSyntax` visitor), `context.shouldRewrite(NoForceTry.self, …)` is evaluated twice — once before `willEnter`, once before `didExit`. With six state-bearing rules on `ClassDecl`, that's 12 `shouldRewrite` calls. Each does a `RuleMask` location lookup + `Configuration.isActive` map lookup. Per node. Across the whole file walk this is a measurable hot path.

The two checks must agree (the rule is either active for this node or it isn't). Cache the result of the first check, or — given that compact-style rules aren't user-toggleable — drop the gate for them entirely.

**Action**: cache the gate decision in a local at the start of each visit, or remove the gate for the static-format pipeline and rely on `RuleMask` only at file boundaries (the `// sm:ignore` comment cases are handled by the rule itself anyway, since each `transform` already early-returns on uninteresting input).

### 4. `RedundantAccessControl` is 600 lines of variations on "remove a modifier"

`Sources/SwiftiomaticKit/Rules/Redundancies/RedundantAccessControl.swift` has:
- 11 `static func transform(_ node: <Decl>Syntax, …)` overloads (lines 58-160), each calling the generic `removeRedundantInternal`
- Two giant `SyntaxEnum`-switching helpers `rewrittenDeclForPublic` (246-272) and `rewrittenDeclForExtensionACL` (298-354), each with 10 nearly-identical cases
- Three near-identical generic helpers `removeRedundantInternal`, `removePublic`, `removeExtensionACLModifier` (194-217, 274-294, 356-382) — they all do "find the modifier, save its leadingTrivia, remove it, re-attach the trivia to either the next modifier or the keyword"

The `WritableKeyPath<Decl, TokenSyntax>` for the keyword exists only to re-attach trivia when modifiers become empty. But trivia of a node equals trivia of its first token, and every `DeclSyntaxProtocol` has `with(\.leadingTrivia, …)`. So the keypath plumbing is unnecessary.

**Action**: collapse to a single helper:
```swift
static func removeModifiers<Decl: DeclSyntaxProtocol & WithModifiersSyntax>(
    _ keywords: Set<Keyword>,
    from decl: Decl, message: Finding.Message, context: Context
) -> Decl {
    guard let mod = decl.modifiers.first(where: { keywords.contains($0.name.tokenKind) }) else { return decl }
    let trivia = mod.leadingTrivia
    diagnose(message, on: mod.name, context: context)
    var r = decl
    r.modifiers = r.modifiers.filter { !keywords.contains($0.name.tokenKind) }
    return r.with(\.leadingTrivia, trivia)
}
```

This collapses the 11 `transform` overloads, both `rewrittenDeclFor*` switches, and the three keyword-keypath helpers into one ~10-line function. The four sub-rules (RedundantInternal, RedundantPublic, RedundantExtensionACL, RedundantFileprivate) become four call sites against it. Estimated reduction: 600 → ~150 lines.

### 5. The same SyntaxEnum-switch pattern recurs in `ClassDecl.swift`'s `removeFinalFromMember`

`Sources/SwiftiomaticKit/Rewrites/Decls/ClassDecl.swift:139-201` has 7 near-identical `if let funcDecl = decl.as(...)` / `if let varDecl = decl.as(...)` / etc. blocks that each do "find `final`, diagnose, remove `final`". Same fix as above: a single generic helper over `WithModifiersSyntax` types, dispatched once via `SyntaxEnum`.

### 6. Per-rule `lazy var` state on `Context` couples the registry to the support module

`Sources/SwiftiomaticKit/Support/Context.swift:57-74` declares 18 `lazy var <rule>State = ...` properties. Adding a new stateful rule requires editing `Context`. A `[ObjectIdentifier: AnyObject]` keyed by rule type (initialized on first access via a `state(for: NoForceTry.self) { Self.State() }` accessor) keeps the same per-file lifetime without the registration step. Slightly slower (a single dictionary lookup per access) but removes a cross-cutting edit point.

This one is lower priority — the current code works; only flag if/when adding state becomes friction.

### 7. `Finding.diagnose` machinery is paid even when nobody is listening

`Sources/SwiftiomaticKit/Syntax/SyntaxRule.swift:38-96` does configuration lookup → severity check → source location resolution → category construction → emit, every time a format rule wants to record "I removed something". For format-only runs (no `--lint`), the diagnostic is discarded, but the location lookup (`startLocation(converter:)`) still runs. Cheap individually, but called once per modification.

**Action**: gate the location lookup behind a `findingEmitter.isAttached` flag, or split format-only mode to skip diagnose calls entirely.

## Plan

Tackle in priority order; each step is independently shippable:

1. **High** — collapse `RedundantAccessControl`'s three keyword-keypath helpers + two SyntaxEnum-switches into one generic `removeModifiers` (~450 line reduction).
2. **High** — delete `Rewrites/Decls/*.swift`, `Rewrites/Exprs/*.swift`, `Rewrites/Stmts/*.swift`; extend `PipelineGenerator` to emit the rule sequence directly into the per-node visit body in `CompactStageOneRewriter+Generated.swift`.
3. **High** — delete `context.applyRewrite`; emit raw transform calls.
4. **Medium** — collapse `ClassDecl`'s `removeFinalFromMember` switch the same way as RedundantAccessControl.
5. **Medium** — cache the `shouldRewrite` decision per visit (one local var) so willEnter/didExit don't re-check.
6. **Low** — gate diagnostic location lookup on `findingEmitter` attachment.
7. **Low / deferred** — replace `Context`'s 18 `lazy var ...State` properties with a typed dictionary on first friction.

After (1)-(3) the typical reader's path through a format pipeline reduces from "open `CompactStageOneRewriter+Generated.swift` → see `rewriteFunctionDecl` call → open `Rewrites/Decls/FunctionDecl.swift` → see `applyRewrite` call → open `Context.swift` → see `transform` call → open the rule" to "open the generated visit method → see the rule's transform call inline".

## Out of scope

- Layout/`TokenStream+*.swift` files. These are large but each token-stream extension does substantive, non-duplicated work; collapsing them would obscure rather than clarify. Same for `LayoutCoordinator.swift`. The pretty printer is already a single direct walk.
- `LintPipeline` — driven by the generator and already minimal.
- Schema/configuration generation — orthogonal to the rewrite hot path.



## Summary of Changes

Picked off the contained, high-impact items from the plan. Steps 2/3 (delete `Rewrites/{Decls,Exprs,Stmts}/*.swift` + remove `applyRewrite`) and step 5 (cache `shouldRewrite` per visit) remain — those are larger mechanical changes touching every visit method and 50+ wrapper files; deferred to follow-ups.

### Done

**Step 1 — `RedundantAccessControl` collapsed (663 → 491 lines).**
- Replaced three near-identical generic helpers (`removeRedundantInternal`, `removePublic`, `removeExtensionACLModifier`) with the existing `removingModifiers(_:keyword:)` extension (already lived in `Sources/SwiftiomaticKit/Extensions/ModifierListSyntax+Convenience.swift`).
- Replaced the two SyntaxEnum-switching helpers (`rewrittenDeclForPublic`, `rewrittenDeclForExtensionACL`) with a single `DeclSyntax.removingModifiers(_:)` extension that dispatches once via `SyntaxEnum`.
- The 11 `transform` overloads are now one-line passthroughs to `removeRedundantInternal` (+ `removePublicFromMembers` for type decls). The extension transform delegates to a unified `removeMatchingAccessControl` + `rewriteMemberBlock` helper that takes the finding message from the caller (so the extension keyword finding stays distinct from the redundant-public finding).

**Step 4 — `ClassDecl.removeFinalFromMember` collapsed (60 lines → 6).**
- The 7 near-identical `if let funcDecl = decl.as(...) { ... }` blocks are now a single `decl.modifiersOrNil`/`decl.removingModifiers([.final])` call using the new `DeclSyntax` extension.

**Step 6 — Diagnose location lookup gated on attached emitter.**
- Added `FindingEmitter.isAttached` and short-circuit `SyntaxRule.diagnose` (both static and instance variants) on it, so `startLocation(converter:)` is skipped for runs with no consumer attached.

### Deferred to follow-ups

- **Step 2/3** — delete `Rewrites/{Decls,Exprs,Stmts}/*.swift` and `Context.applyRewrite`; inline rule transforms directly into the hand-written `CompactStageOneRewriter.swift` visit methods. ~3300 lines to relocate; should be its own change so review can focus on it.
- **Step 5** — cache `shouldRewrite` per visit. Mechanical pass over every `visit(_:)` method in `CompactStageOneRewriter.swift` to extract `let canRun<Rule> = context.shouldRewrite(...)` once.
- **Step 7** — replace per-rule `lazy var ...State` properties on `Context` with a typed dictionary. Low priority per the plan — only touch when adding state becomes friction.

### Validation

- `swift_package_test` clean: 3010 passed, 0 failed.
