# Format Rule Patterns: Wrapping and Token Scanning

Recipes for wrapping braces, wrapping comments, scanning tokens for eligibility checks, and walking method call chains.

## Token Scanning for Eligibility Checks

When a rule needs to check whether a name appears in a syntax subtree (e.g., "does generic type T appear in the function body?"), iterate tokens rather than walking the AST:

```swift
private func contains(name: String, in node: Syntax) -> Bool {
    node.tokens(viewMode: .sourceAccurate)
        .contains { $0.tokenKind == .identifier(name) }
}

private func countOccurrences(of name: String, in node: Syntax) -> Int {
    node.tokens(viewMode: .sourceAccurate)
        .filter { $0.tokenKind == .identifier(name) }
        .count
}
```

This is simpler and more reliable than walking specific node types — it catches the name in any context (type annotations, generic arguments, member access bases, etc.).

**Scope-specific checks**: Pass the specific syntax scope as `Syntax(...)`:
- Parameter list: `Syntax(parameterClause)` — counts in parameter types only
- Return type: `Syntax(returnClause)` — catches `T` in `-> T` or `-> Set<T>`
- Body: `Syntax(body)` — catches `T` in `typealias Alias = T`
- Attributes: `Syntax(attr)` — catches `T` in `@_specialize(where T == Int)`

Used by: `OpaqueGenericParameters`.

## Wrap Brace to Own Line (Multiline Signature)

Move `{` to its own line when the statement signature is multiline. Key pattern: compare indentation levels rather than scanning for newlines (which catches nested scopes).

```swift
private func wrappedBrace(
    leftBrace: TokenSyntax,
    rightBrace: TokenSyntax
) -> TokenSyntax? {
    guard !leftBrace.leadingTrivia.containsNewlines else { return nil }
    guard rightBrace.leadingTrivia.containsNewlines else { return nil }
    guard let prevToken = leftBrace.previousToken(viewMode: .sourceAccurate) else { return nil }
    let prevIndent = lineIndentation(of: prevToken)
    let closingIndent = rightBrace.leadingTrivia.indentation
    guard prevIndent.count > closingIndent.count else { return nil }
    diagnose(.msg, on: leftBrace)
    return leftBrace.with(\.leadingTrivia, .newline + Trivia(stringLiteral: closingIndent))
}
```

**Trailing whitespace cleanup**: After wrapping `{`, the preceding token may have trailing whitespace from `... {`. Strip it on the parent node's property directly (e.g., `result.elseKeyword.trailingTrivia = ...trimmingTrailingWhitespace`). Each node type has different "last signature token" properties — handle per-visitor.

**TokenStripper helper**: When the preceding token isn't a direct property, use a helper rewriter:

```swift
private class TokenStripper: SyntaxRewriter {
    let targetID: SyntaxIdentifier
    let newTrailing: Trivia
    init(targetID: SyntaxIdentifier, newTrailing: Trivia) { ... }
    override func visit(_ token: TokenSyntax) -> TokenSyntax {
        token.id == targetID ? token.with(\.trailingTrivia, newTrailing) : token
    }
}
// Usage: node = TokenStripper(...).rewrite(Syntax(node)).cast(N.self)
```

Used by: `WrapMultilineStatementBraces`.

## Wrap Comments in Trivia

Visit `TokenSyntax` and modify leading trivia to split long comments. Use `.leadingTrivia(triviaIndex)` anchor for `diagnose` so the finding points at the comment, not the token content.

```swift
public override func visit(_ token: TokenSyntax) -> TokenSyntax {
    var pieces = Array(token.leadingTrivia.pieces)
    // ... find .lineComment / .docLineComment pieces exceeding maxWidth
    // ... word-wrap and replace piece with multiple pieces + newline + indent
    diagnose(.msg, on: token, anchor: .leadingTrivia(originalTriviaIndex))
    return token.with(\.leadingTrivia, Trivia(pieces: pieces))
}
```

**Indentation**: Walk backward from the comment piece in trivia to find `.spaces`/`.tabs` after the last `.newlines`.

**Don't wrap**: comment directives (`MARK:`, `TODO:`, `FIXME:`, `sm:ignore`, etc.) and words that won't fit on a line by themselves (avoids infinite wrapping).

Used by: `WrapSingleLineComments`.

## Walk and Wrap Function Call Chains

Collect all `.period` tokens from a dot-chained expression by walking the AST recursively:

```swift
private func collectChain(
    _ expr: ExprSyntax,
    periods: inout [TokenSyntax],
    hasFunctionCall: inout Bool
) {
    if let callExpr = expr.as(FunctionCallExprSyntax.self) {
        hasFunctionCall = true
        collectChain(callExpr.calledExpression, periods: &periods, hasFunctionCall: &hasFunctionCall)
    } else if let subscript = expr.as(SubscriptCallExprSyntax.self) {
        hasFunctionCall = true
        collectChain(subscript.calledExpression, periods: &periods, hasFunctionCall: &hasFunctionCall)
    } else if let member = expr.as(MemberAccessExprSyntax.self) {
        periods.append(member.period)
        if let base = member.base {
            collectChain(base, periods: &periods, hasFunctionCall: &hasFunctionCall)
        }
    } else if let opt = expr.as(OptionalChainingExprSyntax.self) {
        collectChain(opt.expression, periods: &periods, hasFunctionCall: &hasFunctionCall)
    } else if let force = expr.as(ForceUnwrapExprSyntax.self) {
        collectChain(force.expression, periods: &periods, hasFunctionCall: &hasFunctionCall)
    }
}
```

**AST nesting**: Chains are right-recursive. `a.b().c().d()` parses as `FunctionCallExpr(.d, base: FunctionCallExpr(.c, base: FunctionCallExpr(.b, base: a)))`. `collectChain` walks outermost → base, so reverse after collecting to get source order.

**Preventing double-processing**: Visit only `FunctionCallExprSyntax` and check `isInnerChainCall` — skip if this call's parent is a `MemberAccessExprSyntax` whose parent is another call. This ensures only the outermost call processes the full chain.

**Type access detection**: After a `.period`, if the next token is a capitalized identifier (e.g., `.SomeType`), skip that dot — it's a type access, not a method call.

**Multiline detection via source trivia**: Check `period.leadingTrivia.containsNewlines` — this tells you whether the dot is on its own line in the SOURCE, not after PrettyPrinter layout. Rules that enforce consistency (all-or-nothing wrapping) operate on source trivia, not computed layout. This is the key insight: `wrapMultilineFunctionChains` does NOT need PrettyPrinter changes — it's a source-trivia consistency rule.

**Modifying specific tokens**: Use a `SyntaxRewriter` that matches by `SyntaxIdentifier`:

```swift
private class PeriodTriviaRewriter: SyntaxRewriter {
    let targetID: SyntaxIdentifier
    let newTrivia: Trivia
    override func visit(_ token: TokenSyntax) -> TokenSyntax {
        token.id == targetID ? token.with(\.leadingTrivia, newTrivia) : token
    }
}
```

Used by: `WrapMultilineFunctionChains`.
