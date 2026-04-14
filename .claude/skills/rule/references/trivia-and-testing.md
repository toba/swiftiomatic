# Trivia, super.visit, and Testing

## Trivia Ownership

Each token owns trailing trivia up to (but not including) the next newline. The newline itself is leading trivia of the next token. So `.trailingTrivia` on the last token of a line is typically empty — the `\n` lives on the following token's `.leadingTrivia`.

## Trivia When Removing Syntax Nodes

When removing a node (e.g., `= nil`), the **preceding token's trailing trivia** often has a space for the removed node. Clean it up:

```swift
// Removing `= nil` from `var x: Int? = nil`:
//   `?` has trailing trivia " " (space before `=`) — must be replaced
//   `nil` has trailing trivia "" (empty)
// Result: set typeAnnotation.trailingTrivia = initializer.value.trailingTrivia
```

## Boundary Trivia Transfer

When replacing an expression with a structurally different one, transfer boundary trivia:

```swift
var result = ExprSyntax(replacement)
result.leadingTrivia = originalNode.leadingTrivia   // first token's leading
result.trailingTrivia = originalNode.trailingTrivia  // last token's trailing
```

`ExprSyntax.leadingTrivia` sets the first token's leading trivia; `.trailingTrivia` sets the last token's trailing trivia.

## Where Clause Trivia

**Removing entire where clause**: Set to `nil`. The space before `{` is preserved on the preceding token's trailing trivia (e.g., `>` or `)` ).

**Partial where clause rebuild**: Strip leading trivia from the new first requirement — the `where` keyword's trailing trivia provides the space. Set first requirement's `leadingTrivia = []`, NOT `.space` (that creates a double space).

```swift
if i == 0 { r.leadingTrivia = [] }  // NOT .space — where keyword has trailing space
if i == remainingRequirements.count - 1 { r.trailingComma = nil }
```

## super.visit Rules

**The real criterion**: does this node have descendants that another visitor in this rule needs to visit?

- Container types (classes, structs, enums, actors, protocols, extensions) — **always** need `super.visit`
- "Leaf" declarations — need `super.visit` **only if** the rule also visits child node types (e.g., `AttributedTypeSyntax` in parameter types)
- Skipping `super.visit` silently prevents ALL descendant visitors from firing

```swift
// Container: always super.visit first
let visited = super.visit(node).cast(ClassDeclSyntax.self)

// Leaf with child visitors: MUST super.visit
let visited = super.visit(node).cast(FunctionDeclSyntax.self)

// Leaf without child visitors: super.visit not needed
return DeclSyntax(transform(node))
```

**#1 cause of "visitor not firing"**: Missing `super.visit` in a parent visitor when the rule visits both a declaration type AND a child node type.

## Format Rules in the LintPipeline

`SyntaxFormatRule` subclasses are also called by the `LintPipeline` via `visitIfEnabled` (return value ignored). `diagnose()` fires in both passes — no separate lint visitor needed.

## Marker Placement

Place markers at the first non-trivia token of the node passed to `diagnose()`:

```swift
// diagnose(.msg, on: initializerClause) — starts with `=`
var x: Int? 1️⃣= nil    // ✅ marker at `=`
var x: Int?1️⃣ = nil    // ❌ before the space
```

## assertFormatting Mechanics

Runs **two passes**:
1. Single format rule: `visit()` → compare output + findings
2. Full pipeline (`SwiftiomaticFormatter`): format + lint → compare output + findings

Both must produce identical output and findings. If the pipeline reformats differently, the second assertion fails.

`Configuration.forTesting(enabledRule:)` disables ALL rules except the one under test — no interference.

## Adapt SwiftFormat Reference Tests

The SwiftFormat reference at `~/Developer/swiftiomatic-ref/SwiftFormat/Tests/Rules/` has extensive edge-case tests. **Always adapt them** — they catch real bugs:

- Double-space in partial where clause rebuilds (caught in `GenericExtensions`)
- Guard conditions for `case let` patterns, `repeat while`, `try?`/`try!`
- Multiple trailing closures breaking keyPath conversion

Pattern: read reference test file → identify untested code paths → adapt to `assertFormatting`. Skip token-level spacing tests (swift-syntax handles structurally).

## Known Limitations

**Node removal requires parent-level visitation**: Can't return "nothing" from `visit`. Visit the parent collection and filter.

**Backtick identifiers**: Stored as part of token text. Use `Identifier(token).name` for stripped name. `startLocation` points to opening backtick.

**`assertFormatting` two-pass divergence**: If the full pipeline produces different output than the single rule, the test fails even if the single-rule output is correct.
