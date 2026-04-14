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
