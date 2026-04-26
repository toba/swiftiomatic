---
# lhe-lqu
title: '@DeclVisitor macro: eliminate 516 boilerplate visit overrides across 193 rules'
status: draft
type: epic
priority: normal
created_at: 2026-04-17T21:56:55Z
updated_at: 2026-04-26T17:46:58Z
sync:
    github:
        issue_number: "322"
        synced_at: "2026-04-26T18:08:47Z"
---

193 of 217 rules have fan-out visit() overrides (516 total) where each override is 3-6 lines calling the same helper. Roughly ~1,500–2,000 lines of mechanical boilerplate.

## Approach

Introduce a Swift member macro (`@DeclVisitor` or similar) that expands at compile time inside the rule's class body to emit the fan-out `visit()` overrides. Macros — not the existing `generate-swiftiomatic` codegen — are the only approach considered here. Manual codegen / source rewriting is explicitly out of scope: it cannot inject overrides into the class body cleanly, fights the type system, and adds a build step rather than removing one.

### Pattern categories

- **Pattern A** (~60%): Simple dispatch — `visit(FunctionDeclSyntax)` → `processNamedDecl(node)`
- **Pattern B** (~15%): State management — push/pop scope + `super.visit()`
- **Pattern C** (~25%): KeyPath-based — `collapseModifierLines(of: node, keywordKeyPath: \.funcKeyword)`

### Top targets by override count

- RedundantSelf: 22 overrides
- NestingDepth: 18 overrides
- WrapMultilineStatementBraces: 16 overrides
- ModifiersOnSameLine: 15 overrides
- NoLeadingUnderscores: 14 overrides
- RedundantAccessControl: 12 overrides
- CyclomaticComplexity: 12 overrides
- NoForceUnwrap: 11 overrides
- TripleSlashDocComments: 11 overrides
- RequireDocCommentSummary: 11 overrides

Note: the central `processNamedDecl(node)` helper named in Pattern A was never introduced; rules use rule-local equivalents (`enterType`, `process`, etc.) of the same shape.

### Tasks

- [ ] Add macro infrastructure: new SPM target with the compiler plugin, SwiftSyntax/SwiftSyntaxMacros deps
- [ ] Build a one-rule prototype: confirm `@DeclVisitor(...)` emits valid `override func visit(...)` members and that both pipelines dispatch to them
- [ ] Teach `RuleCollector` to discover rules via the `@DeclVisitor(...)` attribute on the class decl, reading the node-type list from the attribute arguments (replaces the member walk at `Sources/GeneratorKit/RuleCollector.swift:154-162`)
- [ ] Finalize the macro surface — parameterized by node-type set and dispatch style (Pattern A simple dispatch, Pattern B scope push/pop, Pattern C KeyPath-based). Consider folding `group`, `customKey`, `isOptIn` into the same attribute (or a sibling `@Rule(...)`)
- [ ] Survey all 193 rules with overrides to classify which pattern each uses
- [ ] Migrate rules to the macro, removing manual overrides
- [ ] Verify build + tests pass



## Architecture Analysis

Macros expand inside the class body, so the `override`-in-extensions problem that blocked external codegen does not apply. Two real requirements the macro design must satisfy:

### Requirement 1: Dual pipeline dispatch
Format rules' visit overrides serve TWO pipelines:
- **FormatPipeline**: SyntaxRewriter dispatch (transform nodes)
- **LintPipeline**: `visitIfEnabled(Rule.visit, for: node)` calls the override by method reference for diagnostic side effects

Macro-generated overrides must be ordinary `override func visit(...)` methods so both pipelines pick them up — same as a hand-written override. This is straightforward for `MemberMacro` output.

### Requirement 2: RuleCollector discovery — turn it into a win
`RuleCollector` currently infers each rule's visited-node set by scanning member decls for functions named `visit` and reading their first parameter type (`Sources/GeneratorKit/RuleCollector.swift:154-162`). That's brittle: visited nodes are implicit in N method signatures, a typo silently drops a node, and a rule with zero overrides is invisible.

The macro inverts this. `@DeclVisitor(.functionDecl, .structDecl, ...)` becomes the single declarative source of truth for *which nodes a rule visits* — both for the collector and for the generated overrides themselves. Concretely the macro can make discovery **simpler and more reliable** than today:

- **One scan target instead of many.** Collector looks for the `@DeclVisitor` attribute on the rule type and reads its argument list. No iterating members, no parameter-type pattern matching.
- **Compile-time validation.** The macro fails the build if a node-type token isn't a real `*Syntax` type, if the attribute is missing on a rule that needs it, or if dispatch-style parameters are inconsistent. Today these are silent omissions.
- **Subsume more metadata.** The same attribute (or a sibling `@Rule(...)`) can carry `group`, `customKey`, `isOptIn`, and dispatch style — currently extracted from scattered constructs (doc comments, separate static properties, member walks). Collector code shrinks; rule files become a single declarative header.
- **No silent exclusions.** Today a rule with no `visit` methods is dropped from the dispatch table. With the attribute present, the rule is always discoverable; an empty node-type list is an explicit, checkable choice.

Fallbacks if the attribute-scan approach hits a wall: have the macro emit a sibling manifest (e.g. a static `visitedNodeTypes` property) the collector reads, or run the collector against post-expansion source. Attribute-scan is preferred — same SwiftSyntax pass the collector already does, and it produces the cleanest rule-author ergonomics.

### Approach: MemberMacro

`@DeclVisitor` (a `MemberMacro`) generates visit overrides at compile time. Clean, type-safe, works with both FormatPipeline (SyntaxRewriter dispatch) and LintPipeline (`visitIfEnabled` method reference). Requires adding macro infrastructure (new SPM target, compiler plugin, SwiftSyntaxMacros deps).

### Bonus: existing codegen migration

Once macro infrastructure exists, audit the current `generate-swiftiomatic` outputs (`Pipelines+Generated.swift`, `ConfigurationRegistry+Generated.swift`, `TokenStream+Generated.swift`) for pieces that could move to macros — but **only** if the macro version is measurably more performant *and* more reliable than the build-tool plugin. Don't migrate for aesthetics; the existing codegen works.

### Recommendation
Defer to when macro infrastructure is needed for another purpose (amortize setup cost). The boilerplate is annoying but not a correctness or maintainability risk.



## Re-evaluation 2026-04-26

Rule count grew ~4x (53 → 217); override count grew ~1.8x (289 → 516). Sub-linear growth reflects increasing reuse of base-class helpers and a long tail of config-only / non-visiting rules (24 of 217).

- **Patterns unchanged.** Pattern A (simple dispatch, ~60%), Pattern B (push/pop scope, ~15%), Pattern C (KeyPath-based `collapseModifierLines`, still confined to `ModifiersOnSameLine` only).
- **Pipeline + collector behavior re-verified.** `LintPipeline.visitIfEnabled<V, Rule, Node>` still dispatches format rules' visit overrides (`Sources/SwiftiomaticKit/Core/LintPipeline.swift`) — macro-generated overrides will work transparently. `RuleCollector` still discovers visited node types by scanning source for functions literally named `visit` (`Sources/GeneratorKit/RuleCollector.swift:154-162`) — it must be taught to read the macro's argument list (or a sibling manifest) since it cannot see post-expansion members.
- **No new mitigations landed.** No member macros (`@DeclVisitor` etc.). `RewriteSyntaxRule` / `LintSyntaxRule` base classes remain minimal — no shared `withNamedDeclScope()`. `Pipelines+Generated.swift` centralizes pipeline-level dispatch but does not reduce per-rule overrides.

**Recommendation unchanged:** defer until macro infrastructure is added for another purpose, so the setup cost can be amortized. The boilerplate is annoying when authoring new rules but is not a correctness or maintainability risk.



## Implementation plan (2026-04-26)

Reference architecture: Thesis macros at `/Users/jason/Developer/toba/thesis/Core/Macros` (`Package.swift`, `Sources/ThesisMacroPlugin/`, `Tests/ThesisMacroTests/`) and the macro patterns reference at `~/.claude/skills/swift/references/swift-macros.md`.

### Package layout (mirrors Thesis)

Add to root `Package.swift`:

- `.macro(name: "SwiftiomaticMacroPlugin")` — compiler plugin target depending on `SwiftSyntax`, `SwiftSyntaxMacros`, `SwiftDiagnostics`, `SwiftCompilerPlugin`. Pin swift-syntax to a single major (`600.0.0..<604.0.0` or current toolchain match).
- `.target(name: "SwiftiomaticMacros")` — thin re-export library exposing `@DeclVisitor` declarations via `#externalMacro`.
- `SwiftiomaticKit` adds `SwiftiomaticMacros` as a dependency.
- `.testTarget(name: "SwiftiomaticMacroTests")` depending on `SwiftiomaticMacroPlugin` + `MacroTesting` (pointfreeco/swift-macro-testing).

Plugin entry point (`Plugin.swift`) follows Thesis pattern: `@main struct Plugin: CompilerPlugin { let providingMacros: [Macro.Type] = [DeclVisitorMacro.self] }`.

### Macro surface

```swift
@attached(member, names: arbitrary)
public macro DeclVisitor(_ kinds: DeclVisitor.NodeKind...) =
    #externalMacro(module: "SwiftiomaticMacroPlugin", type: "DeclVisitorMacro")

public enum DeclVisitor {
    public enum NodeKind {
        case actorDecl, classDecl, structDecl, enumDecl, protocolDecl, extensionDecl
        case functionDecl, initializerDecl, subscriptDecl, variableDecl, typealiasDecl
        case associatedTypeDecl, deinitializerDecl, enumCaseDecl, importDecl, macroDecl
        case operatorDecl, precedenceGroupDecl
        // (full set covers the 17 declaration types currently visited)
    }
}
```

Usage on a Pattern A rule:

```swift
@DeclVisitor(.functionDecl, .initializerDecl, .subscriptDecl, .variableDecl)
final class TripleSlashDocComments: LintSyntaxRule<BasicRuleValue>, @unchecked Sendable { ... }
```

The macro emits one `override func visit(_:)` per kind, each calling a fixed helper convention (see Pattern A/B/C below). The helper name is provided by `Pattern.helper:` argument when non-default.

### Patterns supported

- **Pattern A — simple dispatch**: each generated override calls `processDecl(node)` (or a per-rule helper named via `helper:`). Returns `DeclSyntax(node)` for `RewriteSyntaxRule`, no return for `LintSyntaxRule`.
- **Pattern B — push/pop scope**: each override wraps `super.visit(node)` in `enterScope(node) { ... }` / `defer { leaveScope() }`. Macro takes `style: .scoped(enter: "enterType", leave: "leaveType")`.
- **Pattern C — KeyPath dispatch**: e.g. `ModifiersOnSameLine` calls `collapseModifierLines(of: node, keywordKeyPath: \.funcKeyword)`. Macro takes a per-kind keyword keypath table; emits one override per (kind, keypath) pair.

Most rules use Pattern A. Some (notably `RedundantAccessControl`, `WrapMultilineStatementBraces`) chain multiple helpers per kind — those need either a custom-body escape hatch or remain hand-written (acceptable; macro reduces the bulk).

### RuleCollector changes

`Sources/GeneratorKit/RuleCollector.swift:154-162` currently iterates `members` looking for `function.name.text == "visit"`. Replace with: walk the class decl's `attributes`, find one named `DeclVisitor`, parse its `LabeledExprListSyntax` for `.foo` member-access expressions, map each to the corresponding `*Syntax` type name. The existing `visitedNodes` array is built from that list. Hand-written `visit(_:)` overrides (for rules not yet migrated, or those that can't use the macro) continue to work — both paths populate `visitedNodes`.

### Diagnostics

Macro emits `MacroExpansionErrorMessage` for: empty kind list; unknown kind token; rule type not inheriting from `LintSyntaxRule`/`RewriteSyntaxRule`; `helper:` name that isn't a valid identifier.

### Testing

`Tests/SwiftiomaticMacroTests/DeclVisitorMacroTests.swift` uses `MacroTesting`'s `assertMacro { ... } expansion: { ... }` snapshot style for: Pattern A single kind, Pattern A multiple kinds, Pattern B scope, Pattern C KeyPath, each diagnostic case.

### Execution split (child issues)

1. **Phase 1** — Add macro infrastructure (SPM target + plugin), implement Pattern A only, teach `RuleCollector` to read `@DeclVisitor` attributes, migrate one prototype rule (e.g. `TripleSlashDocComments` — 11 overrides, pure Pattern A).
2. **Phase 2** — Extend macro to support Pattern B (scope push/pop) and Pattern C (KeyPath), with snapshot tests for each.
3. **Phase 3** — Bulk migrate the remaining ~190 rules. Remove the legacy member-walk fallback from `RuleCollector` once nothing uses it.

Phase 4 (follow-up, only if measurably better): audit `Pipelines+Generated.swift`, `ConfigurationRegistry+Generated.swift`, `TokenStream+Generated.swift` for outputs that could move to macros.
