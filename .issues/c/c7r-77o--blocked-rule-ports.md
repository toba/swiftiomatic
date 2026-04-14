---
# c7r-77o
title: Blocked rule ports
status: in-progress
type: epic
priority: normal
created_at: 2026-04-14T04:25:28Z
updated_at: 2026-04-14T05:53:44Z
sync:
    github:
        issue_number: "293"
        synced_at: "2026-04-14T06:15:33Z"
---

Rules from porting efforts that are blocked by tooling or architectural issues and need investigation before they can be implemented.

## Rules

- [ ] `strongifiedSelf` — Remove backticks around `self` in optional unwrap expressions (`guard let \`self\` = self` → `guard let self = self`). **Blocked**: swift-syntax represents backtick-escaped identifiers (`\`self\``) with opaque token positioning that doesn't align with `MarkedText` marker offsets in the test infrastructure. The `diagnose(on:)` anchor resolves to an unpredictable source position, causing `FindingSpec` assertions to fail. Needs investigation into how `TokenSyntax` reports `startLocation` for backtick-quoted keywords. Additionally, as a `SyntaxFormatRule`, the pipeline output diverges from single-rule output (likely pretty-printer interaction with the replaced token). Parent: kt4-gwr.


- [ ] `redundantPattern` — Remove redundant pattern matching (e.g. `case .foo(let _)` → `case .foo(_)`). **Blocked**: swift-syntax does not produce `ValueBindingPatternSyntax` for inner case patterns like `case .bar(let _)`. The `let _` inside function-call-style enum patterns is represented differently (likely `UnresolvedPatternExprSyntax`), so the lint pipeline visitor never fires. Needs investigation into how patterns inside enum case associated values are represented in the AST. Parent: nnl-svw.
- [ ] `redundantFileprivate` — Prefer `private` over `fileprivate` where equivalent. **Blocked**: requires extending the existing `FileScopedDeclarationPrivacy` rule rather than creating a standalone rule. Needs architectural decision on whether to modify the existing rule or create a new one that handles non-file-scope contexts. Parent: nnl-svw.
- [ ] `redundantParens` — Remove redundant parentheses beyond just conditions. **Blocked**: requires extending the existing `NoParensAroundConditions` rule to cover additional contexts (return statements, assignments, etc.). Parent: nnl-svw.
- [ ] `redundantSelf` — Insert/remove explicit `self` where applicable (configurable). **Blocked**: requires scope analysis to determine whether `self` is necessary (variable shadowing, closure capture). This is one of the most complex rules in nicklockwood/SwiftFormat and needs significant design work. Parent: nnl-svw.


- [x] `andOperator` — Resolved: visit `ConditionElementListSyntax` directly instead of child elements. Format rule flattens `&&` chains into separate condition elements.
- [x] `preferCountWhere` — Resolved: visit `MemberAccessExprSyntax` for `.count`, replace entire chain with `FunctionCallExprSyntax` for `.count(where:)`.
- [x] `hoistTry` — Resolved: visit `FunctionCallExprSyntax`, strip `TryExprSyntax` from arguments, wrap call in new `TryExprSyntax`.
- [x] `hoistAwait` — Resolved: same pattern as `hoistTry` with `AwaitExprSyntax`.
- [x] `preferKeyPath` — Resolved: visit `FunctionCallExprSyntax`, replace closure with `KeyPathExprSyntax` in arguments. Trailing closures converted to parenthesized form.
- [x] `simplifyGenericConstraints` — Resolved: generic helper with key paths visits each declaration type, modifies generic params and where clause in one pass.
- [x] `genericExtensions` — Resolved: visit `ExtensionDeclSyntax` container, modify extended type with `GenericArgumentClauseSyntax`, rebuild or remove where clause.
- [x] `isEmpty` — Resolved: visit `InfixOperatorExprSyntax`, return different `ExprSyntax` types (`MemberAccessExprSyntax`, `PrefixOperatorExprSyntax`, or new `InfixOperatorExprSyntax` for optional chains).


- [ ] `opaqueGenericParameters` — Use `some Protocol` instead of `<T: Protocol>`. **Blocked**: format rule requires coordinated modification of generic parameter lists, where clauses, and function parameter types. Must track generic type usage across the entire declaration to determine eligibility. 200+ lines in SwiftFormat reference.
- [ ] `conditionalAssignment` — Use if/switch expressions for assignment. **Blocked**: format rule requires recognizing multi-statement patterns (`let x; if c { x = a } else { x = b }`) spanning separate `CodeBlockItemSyntax` nodes and merging them into a single `let x = if c { a } else { b }`. Cross-statement AST restructuring.
- [ ] `environmentEntry` — Use `@Entry` macro for EnvironmentValues. **Blocked**: format rule requires recognizing the `EnvironmentKey` struct + `EnvironmentValues` extension pattern spanning separate declarations, removing the key struct, and replacing the computed property with `@Entry var`. Cross-declaration restructuring.


- [ ] `redundantProperty` — Remove property assigned and immediately returned. **Blocked**: format rule requires cross-statement restructuring (merging `let result = x; return result` into `return x`). SyntaxRewriter visits individual statements, can't easily merge adjacent `CodeBlockItemSyntax` nodes.
- [ ] `redundantBackticks` — Remove unnecessary backticks from identifiers. **Blocked**: same backtick token positioning issue as `strongifiedSelf`. `TokenSyntax.startLocation` doesn't align with `MarkedText` marker offsets for backtick-quoted identifiers.
- [ ] `redundantClosure` — Remove immediately-invoked closures. **Blocked**: format rule requires unwrapping `{ return x }()` (a `FunctionCallExprSyntax` wrapping a `ClosureExprSyntax`) into just `x`, with correct trivia transfer from surrounding context.
- [ ] `redundantEquatable` — Remove hand-written `Equatable`. **Blocked**: format rule requires coordinated removal of `Equatable` from inheritance clause AND the `==` static function from the member block.
- [ ] `redundantSendable` — Remove explicit `Sendable` conformance. **Blocked**: format rule requires removing a single inherited type from `InheritanceClauseSyntax`, handling comma/colon cleanup when it's the only, first, middle, or last item.


- [ ] `redundantObjc` — Remove `@objc` implied by another attribute. **Blocked**: format rule requires removing an attribute from `AttributeListSyntax` across 7 different declaration types, each with different return types. Trivia cleanup (newlines between attributes) adds complexity.
- [ ] `redundantExtensionACL` — Remove matching access modifier from extension members. **Blocked**: format rule requires removing a `DeclModifierSyntax` from `DeclModifierListSyntax` across multiple declaration types, with trivia cleanup.
- [ ] `redundantPublic` — Remove ineffective `public` modifier. **Blocked**: same as redundantExtensionACL — modifier removal from `DeclModifierListSyntax` across declaration types.
- [ ] `redundantLet` — Remove `let` from `let _ = expr`. **Blocked**: format rule requires removing the `let` keyword from a `VariableDeclSyntax` and preserving the `_ = expr` pattern with correct trivia. The `VariableDeclSyntax` structure ties `let` to the binding specifier.
- [ ] `redundantBreak` — Remove trailing `break` in switch cases. **Blocked**: format rule requires removing a `CodeBlockItemSyntax` from a `CodeBlockItemListSyntax`, with trivia cleanup for the removed statement.
- [ ] `redundantViewBuilder` — Remove `@ViewBuilder`. **Blocked**: same attribute removal issue as redundantObjc.
- [ ] `redundantStaticSelf` — Remove `Self.` prefix in static context. **Blocked**: format rule requires replacing `MemberAccessExprSyntax(base: Self, name: foo)` with `DeclReferenceExprSyntax(foo)`, changing node types entirely.
- [ ] `redundantType` — Remove redundant type annotation. **Blocked**: format rule requires removing `TypeAnnotationSyntax` from `PatternBindingSyntax` while preserving trivia between the pattern and initializer.
- [ ] `redundantAsync` — Remove `async` keyword from function signatures. **Blocked**: format rule requires modifying `FunctionEffectSpecifiersSyntax` to remove the `asyncSpecifier` token, with trivia cleanup.
- [ ] `redundantThrows` — Remove `throws` keyword from function signatures. **Blocked**: same as redundantAsync — modifying effect specifiers.
- [ ] `redundantTypedThrows` — Simplify `throws(any Error)` or `throws(Never)`. **Blocked**: format rule requires modifying `ThrowsClauseSyntax` to remove type parameter or entire clause.
