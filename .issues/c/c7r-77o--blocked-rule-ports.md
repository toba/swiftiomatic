---
# c7r-77o
title: Blocked rule ports
status: in-progress
type: epic
priority: normal
created_at: 2026-04-14T04:25:28Z
updated_at: 2026-04-14T18:30:03Z
sync:
    github:
        issue_number: "293"
        synced_at: "2026-04-14T06:15:33Z"
---

Rules from porting efforts that are blocked or deferred, organized by implementation difficulty. Strategies for each category are documented in sfs-gs8.

## Resolved

These rules have been unblocked and converted to format rules.

- [x] `redundantObjc` — Attribute removal via `AttributeListSyntax+Convenience`
- [x] `redundantViewBuilder` — Attribute removal via `AttributeListSyntax+Convenience`
- [x] `redundantSendable` — Inheritance clause removal via `InheritanceClauseSyntax+Convenience`
- [x] `redundantExtensionACL` — Member modifier removal (stateful rewriting pattern)
- [x] `redundantPublic` — Member modifier removal (`DeclGroupSyntax` pattern)
- [x] `redundantBreak` — Statement removal from `CodeBlockItemListSyntax`
- [x] `redundantAsync` — Effect specifier removal
- [x] `redundantThrows` — Effect specifier removal
- [x] `redundantTypedThrows` — Effect specifier simplify/removal
- [x] `andOperator` — Visit `ConditionElementListSyntax`, flatten `&&` chains
- [x] `preferCountWhere` — Visit `MemberAccessExprSyntax`, replace chain with `.count(where:)`
- [x] `hoistTry` — Visit `FunctionCallExprSyntax`, strip `TryExprSyntax` from arguments, wrap call
- [x] `hoistAwait` — Same pattern as `hoistTry` with `AwaitExprSyntax`
- [x] `preferKeyPath` — Visit `FunctionCallExprSyntax`, replace closure with `KeyPathExprSyntax`
- [x] `simplifyGenericConstraints` — Generic helper with key paths, modify params + where clause
- [x] `genericExtensions` — Visit `ExtensionDeclSyntax`, modify extended type + where clause
- [x] `isEmpty` — Visit `InfixOperatorExprSyntax`, return restructured expression

## Phase 1 — Token/backtick rules

Need investigation into swift-syntax backtick token representation.

- [x] `strongifiedSelf` — Remove backticks around `self` in optional unwrap. **Blocker**: backtick token positioning doesn't align with `MarkedText` marker offsets; pipeline output diverges from single-rule output. Parent: kt4-gwr.
- [x] `redundantBackticks` — Remove unnecessary backticks from identifiers. **Blocker**: same backtick token positioning issue as `strongifiedSelf`. Parent: nnl-svw.
- [x] `redundantPattern` — Remove redundant pattern matching (`case .foo(let _)` → `case .foo(_)`). **Note**: sfs-gs8 analysis shows this is NOT actually blocked — `ValueBindingPatternSyntax` IS produced, just nested inside `PatternExprSyntax`. Parent: nnl-svw.

## Phase 2 — Extend existing rules

Require architectural decisions about modifying existing rules vs standalone.

- [ ] `redundantFileprivate` — Prefer `private` over `fileprivate` where equivalent. Requires extending `FileScopedDeclarationPrivacy` for non-file-scope contexts. Parent: nnl-svw.
- [ ] `redundantParens` — Remove redundant parentheses beyond conditions. Requires extending `NoParensAroundConditions` for return statements, assignments, etc. Parent: nnl-svw.

## Phase 3 — Cross-statement merging

Pattern exists in `UseEarlyExits` (windowed iteration over `CodeBlockItemListSyntax`).

- [ ] `conditionalAssignment` — Use if/switch expressions for assignment. Merge `let x; if c { x = a } else { x = b }` → `let x = if c { a } else { b }`. Cross-statement restructuring.
- [ ] `redundantProperty` — Remove property assigned and immediately returned. Merge `let result = x; return result` → `return x`.
- [ ] `redundantClosure` — Remove immediately-invoked closures. Unwrap `{ return x }()` → `x`.
- [ ] `redundantEquatable` — Remove hand-written `Equatable`. Coordinated removal from inheritance clause AND `==` function from member block.

## Phase 4 — Cross-declaration / complex

- [ ] `environmentEntry` — Use `@Entry` macro for EnvironmentValues. Requires recognizing `EnvironmentKey` struct + `EnvironmentValues` extension pattern spanning separate file-level declarations.
- [ ] `opaqueGenericParameters` — Use `some Protocol` instead of `<T: Protocol>`. Coordinated modification of generic params, where clauses, and parameter types. Must track usage across entire declaration. 200+ lines in SwiftFormat reference.

## Phase 5 — Scope analysis

- [ ] `redundantSelf` — Insert/remove explicit `self` (configurable). Requires scope analysis for variable shadowing and closure capture. Most complex rule in nicklockwood/SwiftFormat (~800 lines). Conservative subset (SE-0269 cases) is feasible first step. Parent: nnl-svw.

## Phase 6 — Large new implementations

Substantial rules not yet ported.

- [ ] `propertyTypes` — Configure inferred vs explicit property types. 325-line SwiftFormat impl, 3 config modes, bidirectional conversion. Parent: ka6-zh3.
- [ ] `trailingClosures` — Use trailing closure syntax. 187-line SwiftFormat impl, multiple trailing closure handling. Parent: ka6-zh3.
- [ ] `unusedArguments` — Mark unused function arguments with `_`. 401-line SwiftFormat impl, scope analysis. Parent: ka6-zh3.
- [ ] `unusedPrivateDeclarations` — Remove unused private declarations. Whole-file analysis, high false-positive risk. Parent: ka6-zh3.
- [ ] `urlMacro` — Replace `URL(string:)!` with `#URL(_:)`. Requires config + import management. Parent: ka6-zh3.
- [ ] `docComments` — Convert `//` to `///` before API declarations. 300+ line impl. Parent: q2z-9o5.
- [ ] `fileHeader` — Enforce file header template. Requires config + file path. Parent: q2z-9o5.
- [ ] `headerFileName` — Ensure header file name matches actual file. Parent: q2z-9o5.
- [ ] `markTypes` — Add `// MARK: -` before types. 400+ line impl. Parent: q2z-9o5.
- [ ] `organizeDeclarations` — Organize members by category. 600+ line impl. Parent: q2z-9o5.

## Deferred

- [ ] `leadingDelimiters` — Move leading `.`/`,` to end of previous line. Multi-token trivia manipulation; trivial in flat token stream, complex in syntax tree. Parent: j0v-ttz.
- [ ] `redundantLet` — Remove `let` from `let _ = expr`. Ties `let` to binding specifier.
- [ ] `redundantStaticSelf` — Remove `Self.` prefix in static context. Node type change (`MemberAccessExprSyntax` → `DeclReferenceExprSyntax`).
- [ ] `redundantType` — Remove redundant type annotation. Already a format rule; listed here for additional coverage (array/generic/closure patterns tracked in pfo-ol9).


## Phase 1 Completion Notes

All three Phase 1 rules implemented as format rules with auto-fix, adapted from SwiftFormat reference tests.

| Rule | Tests | Key Implementation Detail |
|------|-------|--------------------------|
| `StrongifiedSelf` | 5 | Visits `OptionalBindingConditionSyntax`, checks backticked `self` pattern with `self` initializer |
| `RedundantBackticks` | 38 | Converted lint→format. Token visitor with context-aware checks: `MemberAccessExprSyntax`, `MemberTypeSyntax`, `FunctionParameterSyntax`, `MemberBlockSyntax`, accessor/contextual keyword handling |
| `RedundantPattern` | 12 | Visits `SwitchCaseItemSyntax`, `MatchingPatternConditionSyntax`, `VariableDeclSyntax`. Handles hoisted (`case let .foo(_)`) and per-arg (`case .foo(let _)`) patterns |

### Discoveries documented in /rule skill

- Per-arg binding patterns put `let`/`var` as `LabeledExprSyntax.label` with no colon; wildcard expression needs `trimmedDescription` fallback
- `MemberTypeSyntax` (not `MemberAccessExprSyntax`) handles type-level dot access (`Foo.Type`)
- `isInsideTypeDeclaration` must check `MemberBlockSyntax`, not parent type decl (which matches the type's own name)


## Phase 7 — Testing rules (from m0v-ruy)

Complex testing-related rules that require expression-level analysis or full framework migration.

- [ ] `noForceUnwrapInTests` — Replace `!` with `XCTUnwrap`/`#require` wrapping. Requires expression-range parsing, `as!`→`as?` conversion, LHS/RHS analysis, standalone-expression detection. 350+ lines in SwiftFormat. Parent: m0v-ruy.
- [ ] `noGuardInTests` — Convert `guard` to `try #require`/`#expect`. Requires guard condition parsing, variable shadowing detection, building multi-statement replacements. 250 lines in SwiftFormat. Parent: m0v-ruy.
- [ ] `preferSwiftTesting` — Full XCTest→Swift Testing migration. Import rewriting, assertion conversion (`XCTAssert*`→`#expect`), `setUp`/`tearDown`→`init`/`deinit`, conformance removal. 600+ lines across multiple extensions in SwiftFormat. Parent: m0v-ruy.
