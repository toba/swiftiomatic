# AST Structure, Hooks, and Extensions

## ConditionElementSyntax.Condition Kinds

`ConditionElementSyntax.condition` has four cases:

- `.expression(ExprSyntax)` — boolean expression (`a && b`, `foo.isEmpty`)
- `.optionalBinding(OptionalBindingConditionSyntax)` — `let x = foo`
- `.matchingPattern(MatchingPatternConditionSyntax)` — `case let x = foo`
- `.availability(AvailabilityConditionSyntax)` — `#available(iOS 16, *)`

Rules transforming conditions (e.g., `&&` → comma) should only match `.expression`. The other kinds contain `&&` as part of value expressions, not separable conditions.

## Enum Case Pattern AST

Case patterns with associated values are expression patterns containing function calls:

```
case .foo(let x):
SwitchCaseItemSyntax
└─ pattern: ExpressionPatternSyntax
   └─ expression: FunctionCallExprSyntax
      ├─ calledExpression: MemberAccessExprSyntax (.foo)
      └─ arguments: LabeledExprListSyntax
         └─ LabeledExprSyntax
            └─ expression: PatternExprSyntax
               └─ pattern: ValueBindingPatternSyntax (let x)

case .bar(let _):     ← ValueBindingPatternSyntax + WildcardPatternSyntax
case .baz(_):         ← WildcardPatternSyntax (no ValueBindingPatternSyntax)
```

### Modifying Case Pattern Bindings in SyntaxRewriter

The actual AST for `case .bar(let _)` uses `PatternExprSyntax` → `ValueBindingPatternSyntax`,
with `LabeledExprSyntax.label = nil`:

```
case .bar(let _):
FunctionCallExprSyntax
└─ arguments: LabeledExprListSyntax
   └─ LabeledExprSyntax
      ├─ label: nil
      ├─ colon: nil
      └─ expression: PatternExprSyntax
         └─ pattern: ValueBindingPatternSyntax
            ├─ bindingSpecifier: "let"
            └─ pattern: WildcardPatternSyntax
```

**SyntaxRewriter caveat**: returning a different concrete type from a covariant `visit`
(e.g., `WildcardPatternSyntax` from `visit(_ node: ValueBindingPatternSyntax) -> PatternSyntax`)
is **silently ignored** — the visitor IS called but `rewrite()` doesn't apply the change.

**Fix**: modify at the PARENT level. Visit `LabeledExprSyntax` and replace
`node.expression` with a new `PatternExprSyntax` wrapping just the wildcard:

```swift
override func visit(_ node: LabeledExprSyntax) -> LabeledExprSyntax {
    guard let patExpr = node.expression.as(PatternExprSyntax.self),
          let binding = patExpr.pattern.as(ValueBindingPatternSyntax.self),
          binding.pattern.trimmedDescription == "_"  // ← is() fails after child traversal
    else { return node }
    var newPatExpr = patExpr
    newPatExpr.pattern = binding.pattern
    var result = node
    result.expression = ExprSyntax(newPatExpr)
    return result
}
```

**`is()` check caveat**: after SyntaxRewriter's child-first traversal, `is(WildcardPatternSyntax.self)`
on reconstructed nodes may return `false` even when the node IS a wildcard. Use
`trimmedDescription == "_"` as a reliable fallback.

### Backtick Token Representation

swift-syntax stores backticks as part of identifier text: `.identifier("` `` `self` `` `")`.
The `Identifier` type (from `Identifier.swift`) strips backticks via `.name`.
`SyntaxRewriter.visit(_ token: TokenSyntax) -> TokenSyntax` intercepts all tokens — use
`token.with(\.tokenKind, .identifier(bareName))` to remove backticks.

### Member Access: Expression vs Type

`MemberAccessExprSyntax` handles expression member access (`foo.bar`).
`MemberTypeSyntax` handles type member access (`Foo.Type`, `Foo.Protocol`).
Rules checking "after dot" must handle both — e.g., `` Foo.`Type` `` uses `MemberTypeSyntax`,
not `MemberAccessExprSyntax`.

### isInsideTypeDeclaration Pitfall

Walking parent chain for `ClassDeclSyntax`/`StructDeclSyntax`/`EnumDeclSyntax` matches the
type's OWN name token (e.g., `enum `Type` {}` — the name IS inside the `EnumDeclSyntax`).
To check if a token is inside a type's **body**, look for `MemberBlockSyntax` in the parent chain instead.

## SyntaxRewriter Hooks

```swift
open func visitPre(_ node: Syntax) {}     // before node + descendants (read-only)
open func visitPost(_ node: Syntax) {}    // after node + all descendants
open func visitAny(_ node: Syntax) -> Syntax? { nil }  // dynamic dispatch escape hatch
```

**Order**: `visitPre` → `visitAny ?? dispatchVisit` → `visitPost`.

`visitAny` can do protocol-based dispatch but fights the type system. Prefer concrete visit methods. NOTE: `SyntaxFormatRule` already overrides `visitAny` for `shouldFormat()` checks.

## Position & Location

```swift
// SourceLocationConverter — access via context.sourceLocationConverter
let loc = context.sourceLocationConverter.location(for: node.positionAfterSkippingLeadingTrivia)
loc.line    // Int (1-based)
loc.column  // Int (1-based)

// Position properties on syntax nodes
node.position                          // AbsolutePosition — start including leading trivia
node.positionAfterSkippingLeadingTrivia // AbsolutePosition — start of actual text
node.endPosition                       // AbsolutePosition — end including trailing trivia
node.endPositionBeforeTrailingTrivia    // AbsolutePosition — end of actual text
```

## Token Navigation

```swift
node.lastToken(viewMode: .sourceAccurate)
token.nextToken(viewMode: .sourceAccurate)
token.previousToken(viewMode: .sourceAccurate)
```

## Trivia Primitives (swift-syntax)

```swift
// Modify trivia (returns new node — SwiftSyntax is immutable)
token.with(\.leadingTrivia, .space)
token.with(\.leadingTrivia, Trivia(pieces: newPieces))
token.with(\.trailingTrivia, [])

// Common values
Trivia.space                     // single space
Trivia.newline                   // single newline
Trivia(pieces: [.spaces(4)])     // 4 spaces
```

## InitializerClauseSyntax Scope

`InitializerClauseSyntax` (`= value`) fires in multiple contexts:
- Variable initializers: `let x = value`, `var x = value`
- Default parameter values: `func foo(x: Int = value)`
- Enum case raw values: `case foo = value`

This makes it a useful single visitor for "assignment context" transformations (e.g., removing redundant parens around `value`). But its `value` can be any expression — including `IfExprSyntax` (`let x = if cond { }`) or `SwitchExprSyntax` — so the fallback path must call `super.visit(node)` to let other visitors fire on descendants.

## swift-syntax API Notes

**`SameTypeRequirementSyntax.RightType`** — enum: `.type(TypeSyntax)` | `.expr(ExprSyntax)`. Extract via:
```swift
case .type(let rightType) = sameType.rightType
```

**`GenericArgumentSyntax.Argument`** — enum: `.type(TypeSyntax)` | `.expr(ExprSyntax)`. Construct:
```swift
GenericArgumentSyntax(argument: .type(someType), trailingComma: nil)
```

**`BooleanLiteralExprSyntax`** — use `literal:` (not deprecated `booleanLiteral:`):
```swift
BooleanLiteralExprSyntax(literal: .keyword(.true))
```

**`DeclModifierListSyntax`** — `init(_:)` from array is deprecated. Use builder or pass elements directly.

**`TypeSpecifierListSyntax.Element`** — `SyntaxChildChoices` enum. Match: `case .simpleTypeSpecifier(let simple)`. Token: `simple.specifier` with kinds like `.keyword(.borrowing)`.

**`SomeOrAnyTypeSyntax`** — represents `some Protocol` or `any Protocol`:
```swift
// some Fooable
SomeOrAnyTypeSyntax(
    someOrAnySpecifier: .keyword(.some, trailingTrivia: .space),
    constraint: IdentifierTypeSyntax(name: .identifier("Fooable"))
)

// some Fooable & Barable
SomeOrAnyTypeSyntax(
    someOrAnySpecifier: .keyword(.some, trailingTrivia: .space),
    constraint: CompositionTypeSyntax(elements: CompositionTypeElementListSyntax([
        CompositionTypeElementSyntax(
            type: TypeSyntax(IdentifierTypeSyntax(name: .identifier("Fooable"))),
            ampersand: .binaryOperator("&", leadingTrivia: .space, trailingTrivia: .space)),
        CompositionTypeElementSyntax(
            type: TypeSyntax(IdentifierTypeSyntax(name: .identifier("Barable"))))
    ]))
)
```

**Wrapping `some` types in parens** — required for `(some Any).Type` and `(some Any)?`:
```swift
// (some Any).Type
MetatypeTypeSyntax(
    baseType: TupleTypeSyntax(
        leftParen: .leftParenToken(),
        elements: [TupleTypeElementSyntax(type: someAnyType)],
        rightParen: .rightParenToken()),
    period: .periodToken(),
    metatypeSpecifier: .keyword(.Type))
```

**`FunctionParameterSyntax.ellipsis`** — non-nil `TokenSyntax` when parameter is variadic (`T...`). Check this to prevent converting variadic generic parameters to opaque syntax.

**`FunctionTypeSyntax`** — represents closure types like `(Foo) -> Void`. Check `type.is(FunctionTypeSyntax.self)` to detect closure parameters (opaque generics can't appear in closure parameter position).

## Convenience Extensions

### DeclModifierListSyntax
```swift
var accessLevelModifier: DeclModifierSyntax?
func contains(anyOf keywords: Set<Keyword>) -> Bool
mutating func remove(anyOf keywords: Set<Keyword>)
func removing(anyOf keywords: Set<Keyword>) -> Self
```

### Trivia
```swift
var hasAnyComments: Bool
var hasLineComment: Bool
var containsNewlines: Bool
var containsSpaces: Bool
func withoutLeadingSpaces() -> Trivia
func withoutTrailingSpaces() -> Trivia
func withoutLastLine() -> Trivia
```

### SyntaxProtocol
```swift
var allPrecedingTrivia: Trivia      // prev token trailing + node leading
var allFollowingTrivia: Trivia      // node trailing + next token leading
var hasPrecedingLineComment: Bool
var hasAnyPrecedingComment: Bool
var hasTestAncestor: Bool           // walks parent chain for @Test
```

### SyntaxCollection
```swift
var firstAndOnly: Element?          // first element iff count == 1
```

### AttributeListSyntax
```swift
/// Find a plain @Name attribute (ignores @Module.Name and #if-wrapped).
/// Returns the AttributeSyntax including any arguments — caller decides if args disqualify.
func attribute(named name: String) -> AttributeSyntax?

/// Remove by name with trivia transfer to next kept element.
func removing(named name: String) -> AttributeListSyntax
mutating func remove(named name: String)
```

### InheritanceClauseSyntax
```swift
/// Find by trimmedDescription (works for simple and qualified names).
func contains(named typeName: String) -> Bool
func inherited(named typeName: String) -> InheritedTypeSyntax?

/// Remove by name. Returns nil when clause becomes empty — caller must set
/// inheritanceClause = nil AND add .space to memberBlock.leftBrace.leadingTrivia.
func removing(named typeName: String) -> InheritanceClauseSyntax?
```

### WithAttributesSyntax
```swift
func hasAttribute(_ name: String, inModule module: String) -> Bool
```

### FunctionDeclSyntax
```swift
var fullDeclName: String            // e.g. "foo(_:bar:)"
```

## Extension Type Name: Simple vs Nested

`ExtensionDeclSyntax.extendedType` can be:
- `IdentifierTypeSyntax` for simple names: `extension Foo` → `.text == "Foo"`
- `MemberTypeSyntax` for nested types: `extension Foo.Bar` → base type + member name

When checking if an extension extends the same type as a primary declaration, guard with `IdentifierTypeSyntax`:

```swift
guard extDecl.extendedType.as(IdentifierTypeSyntax.self) != nil else { return nil }
return extDecl.extendedType.trimmedDescription  // "Foo"
```

Using `trimmedDescription` without the `IdentifierTypeSyntax` guard would match `Foo.Bar` as a string, but it's a different logical type. The `MemberTypeSyntax` check ensures we only match top-level type extensions.

## swift-syntax Source Reference

Local checkout: `~/Developer/apple/swift-syntax`

| Question | Where to look |
|----------|---------------|
| AST for specific code | `Tests/SwiftParserTest/` |
| Visit method signatures | `Sources/SwiftSyntax/generated/SyntaxRewriter.swift` |
| Node protocol conformances | `Sources/SwiftSyntax/generated/SyntaxTraits.swift` |
| Token representation | `Sources/SwiftSyntax/TokenSyntax.swift`, `Identifier.swift` |
| Node children | `Sources/SwiftSyntax/generated/syntaxNodes/` |
| All node types | `Sources/SwiftSyntax/generated/SyntaxEnum.swift` |

## Upstream References

- **swift-syntax**: `~/Developer/apple/swift-syntax` — AST nodes, visit methods, protocols, tokens
- **swift-format**: `~/Developer/swiftiomatic-ref/swift-format` — architecture patterns, format rule examples
- **SwiftFormat (Lockwood)**: `~/Developer/swiftiomatic-ref/SwiftFormat` — token-based rules in `Sources/Rules/`, tests in `Tests/Rules/`
