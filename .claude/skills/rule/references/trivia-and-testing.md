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

**Removing entire where clause**: Set to `nil`. The space before `{` is preserved on the preceding token's trailing trivia (e.g., `>` or `)`). **Caveat**: for declarations with no body (protocol methods), this trailing space becomes trailing whitespace. Fix by stripping trailing trivia from the preceding syntax element (e.g., `result.signature.trailingTrivia = []` for `FunctionDeclSyntax` when `result.body == nil`).

**Partial where clause rebuild**: Strip leading trivia from the new first requirement — the `where` keyword's trailing trivia provides the space. Set first requirement's `leadingTrivia = []`, NOT `.space` (that creates a double space). **Also**: preserve the original where clause's trailing trivia on the last remaining requirement (e.g., space before `{`). When removing a `trailingComma`, the space that was on the comma's trailing trivia is lost — set `r.trailingTrivia = whereClause.trailingTrivia` to transfer it.

```swift
if i == 0 { r.leadingTrivia = [] }  // NOT .space — where keyword has trailing space
if i == remainingRequirements.count - 1 {
    r.trailingComma = nil
    r.trailingTrivia = whereClause.trailingTrivia  // preserve space before `{`
}
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

### Cascading hoisting (HoistTry/HoistAwait)

Bottom-up visiting means inner calls hoist first, then the outer call sees the generated `try`/`await` and hoists again. This produces **multiple findings** for a single input (one per hoisting level). Tests with nested calls like `foo(.bar(try baz()))` emit 2 findings (inner + outer). Avoid testing these in `assertFormatting` since the pipeline findings count differs from single-rule findings count.

### Diagnostic debugging for tests

When `assertFormatting` fails with truncated diff output (common in MCP test runners), create a temporary diagnostic test that encodes the actual output:

```swift
let actual = "\(formatter.rewrite(sourceFileSyntax))"
let escaped = actual.replacingOccurrences(of: "\n", with: "\\n")
    .replacingOccurrences(of: " ", with: "·")
Issue.record("OUTPUT: \(escaped)")
```

This makes whitespace issues (trailing spaces, missing spaces before `{`) visible in the error message. Delete the diagnostic test after debugging.

## Position Shift When Modifying Statements in a Loop

When iterating through a statement list and modifying earlier entries (e.g., adding `\n` to a statement's leading trivia), later statements in the `var statements = ...` array have shifted positions. If you `diagnose(on: statements[i])` where `statements[i]` was modified by a previous iteration, the finding position will be off (typically +1 column per added newline).

**Fix**: Keep a `let originalStatements = statements` copy and always `diagnose(on: originalStatements[i].item)`:

```swift
let originalStatements = Array(visited.statements)
var statements = originalStatements
for i in 0..<originalStatements.count {
    // Always read from originalStatements for conditions and diagnose targets
    // Always write to statements for modifications
    diagnose(.msg, on: originalStatements[i].item)
    statements[nextIndex] = modified
}
```

## diagnose on `.item`, Not `CodeBlockItemSyntax`

When diagnosing on a statement from `CodeBlockItemListSyntax`, use `statement.item` (the actual `GuardStmtSyntax`, `VariableDeclSyntax`, etc.) rather than the `CodeBlockItemSyntax` wrapper. Both share the same first token, but using `.item` is more precise and avoids subtle position discrepancies.

## Blank Line Detection Must Stop at Comments

When checking leading trivia for blank lines, only count newlines BEFORE the first comment. Comments in trivia (e.g., `\n// comment\n    guard`) produce 2 newlines total but represent zero blank lines — one newline ends the previous line, the other ends the comment.

```swift
// WRONG: counts all newlines including after comments
trivia.pieces.reduce(0) { count, piece in
    if case .newlines(let n) = piece { count + n } else { count }
} >= 2

// RIGHT: only count newlines before first non-whitespace content
var newlines = 0
for piece in trivia.pieces {
    if case .newlines(let n) = piece { newlines += n }
    else if piece.isSpaceOrTab { continue }
    else { break }  // stop at comment or other content
}
let blankLineCount = max(0, newlines - 1)  // -1 for end-of-previous-line
```

## `break` in `switch` Inside `for` Loop

In Swift, `break` inside a `switch` case breaks the **switch**, not the enclosing `for` loop. This is a common gotcha when scanning trivia pieces. Use `if/else` chains or labeled loops:

```swift
// WRONG: break exits switch, loop continues
for piece in trivia.pieces {
    switch piece {
    case .newlines(let n): count += n
    default: break  // only exits the switch!
    }
}

// RIGHT: if/else chain — break exits the for loop
for piece in trivia.pieces {
    if case .newlines(let n) = piece { count += n }
    else if piece.isSpaceOrTab { continue }
    else { break }  // exits the for loop
}
```

## Known Limitations

**Node removal requires parent-level visitation**: Can't return "nothing" from `visit`. Visit the parent collection and filter.

**Backtick identifiers**: Stored as part of token text. Use `Identifier(token).name` for stripped name. `startLocation` points to opening backtick.

**`assertFormatting` two-pass divergence**: If the full pipeline produces different output than the single rule, the test fails even if the single-rule output is correct.
