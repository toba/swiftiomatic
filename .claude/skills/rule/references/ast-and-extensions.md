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

Visit `PatternExprSyntax` or `ValueBindingPatternSyntax` directly.

### Per-Argument Binding Label Quirk

In per-argument patterns like `case .bar(let _, let _)`, the parser puts `let`/`var` as
the `LabeledExprSyntax.label` (with `colon: nil`), NOT as part of the expression.

```
case .bar(let _):
FunctionCallExprSyntax
└─ arguments: LabeledExprListSyntax
   └─ LabeledExprSyntax
      ├─ label: "let"     ← keyword token as label
      ├─ colon: nil        ← no colon (binding specifier, not argument label)
      └─ expression: ???   ← the wildcard `_` in an unusual representation
```

**Critical**: the expression after `let` as label does NOT reliably match
`DiscardAssignmentExprSyntax`, `PatternExprSyntax`, or `DeclReferenceExprSyntax`.
Use `arg.expression.trimmedDescription == "_"` as a fallback.

To distinguish real argument labels from binding specifiers: real labels always have
`arg.colon != nil`. Binding specifiers have `arg.label != nil` but `arg.colon == nil`.

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
