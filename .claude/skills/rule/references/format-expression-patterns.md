# Format Rule Patterns: Expressions and Tokens

Recipes for expression-level transformations: changing node types, visiting tokens, replacing expressions, restructuring chains, hoisting keywords, and removing force-unwrap.

## Change Node Types

Replace one declaration type with another (e.g., `StructDeclSyntax` → `EnumDeclSyntax`):

```swift
public override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
    let visited = super.visit(node).cast(StructDeclSyntax.self)
    let enumDecl = EnumDeclSyntax(
      leadingTrivia: visited.leadingTrivia,
      modifiers: visited.modifiers,
      enumKeyword: .keyword(.enum,
        leadingTrivia: visited.structKeyword.leadingTrivia,
        trailingTrivia: visited.structKeyword.trailingTrivia),
      name: visited.name,
      memberBlock: visited.memberBlock,
      trailingTrivia: visited.trailingTrivia)
    return DeclSyntax(enumDecl)
}
```

## Token Visitors

`visit(_ token: TokenSyntax) -> TokenSyntax` visits every token for renaming/keyword changes:

```swift
public override func visit(_ token: TokenSyntax) -> TokenSyntax {
    guard case .identifier(let text) = token.tokenKind else { return token }
    let updated = transform(text)
    guard updated != text else { return token }
    diagnose(.myMessage, on: token)
    return token.with(\.tokenKind, .identifier(updated))
}
```

Marker placement: at the START of the token.

**Backtick removal pattern**: backticked identifiers have `tokenKind == .identifier("` `` `name` `` `")`.
Check `text.hasPrefix("` `` ` `` `")`, strip backticks, determine if context allows bare name, then
`token.with(\.tokenKind, .identifier(bareName))`. Context checks use parent chain:
`MemberAccessExprSyntax` (after `.`), `FunctionParameterSyntax` (argument label),
`MemberTypeSyntax` (type member like `Foo.Type`), `MemberBlockSyntax` (inside type body).

## Replace Expression Types

Replace an expression with a structurally different one (e.g., `InfixOperatorExprSyntax` → `MemberAccessExprSyntax`):

```swift
public override func visit(_ node: InfixOperatorExprSyntax) -> ExprSyntax {
    let visited = super.visit(node)
    guard let infixNode = visited.as(InfixOperatorExprSyntax.self) else { return visited }
    guard shouldTransform(infixNode) else { return visited }
    diagnose(.msg, on: infixNode)
    var result = ExprSyntax(buildReplacement(infixNode))
    result.leadingTrivia = infixNode.leadingTrivia
    result.trailingTrivia = infixNode.trailingTrivia
    return result
}
```

**Wrapping with prefix operator** (e.g., `!foo.isEmpty`):

```swift
var innerExpr = ExprSyntax(replacement)
innerExpr.leadingTrivia = []
innerExpr.trailingTrivia = node.trailingTrivia
let bang = TokenSyntax(.prefixOperator("!"), leadingTrivia: node.leadingTrivia, trailingTrivia: [], presence: .present)
return ExprSyntax(PrefixOperatorExprSyntax(operator: bang, expression: innerExpr))
```

## Restructure Method Chains

Replace a chain like `.filter { ... }.count` → `.count(where: { ... })`:

```swift
public override func visit(_ node: MemberAccessExprSyntax) -> ExprSyntax {
    // Check parent on ORIGINAL node before super.visit
    if let parent = node.parent?.as(FunctionCallExprSyntax.self),
       parent.calledExpression.id == ExprSyntax(node).id {
        return super.visit(node)  // this is a method call, not property access
    }
    let visited = super.visit(node)
    // ... pattern match, extract closure, build new FunctionCallExprSyntax ...
}
```

**Parent access**: Use `node.parent` on the **original** node, not the visited result (detached from tree).

**Multiple trailing closures**: Check `callNode.additionalTrailingClosures.isEmpty` before converting trailing closures.

## Hoist Expression Wrappers (try/await)

Move `try`/`await` from arguments to wrap the entire call:

```swift
public override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
    if isWrappedInTry(ExprSyntax(node)) { return super.visit(node) }
    let visited = super.visit(node)
    guard let callNode = visited.as(FunctionCallExprSyntax.self),
          let firstTry = findFirstTryInArguments(callNode) else { return visited }
    diagnose(.msg, on: firstTry.tryKeyword)
    let newArgs = callNode.arguments.map { $0.with(\.expression, stripTry(from: $0.expression)) }
    let newCall = callNode.with(\.arguments, LabeledExprListSyntax(newArgs))
    var callExpr = ExprSyntax(newCall)
    callExpr.leadingTrivia = []
    let tryExpr = TryExprSyntax(
        tryKeyword: .keyword(.try, leadingTrivia: node.leadingTrivia, trailingTrivia: .space),
        expression: callExpr)
    var result = ExprSyntax(tryExpr)
    result.trailingTrivia = node.trailingTrivia
    return result
}
```

**Keyword ordering (`try await`)**: Hoisting `try` from inside `await` produces `await try X` (wrong). Fix with an `AwaitExprSyntax` visitor that reorders — but **only when `try` was introduced by child visitation**:

```swift
public override func visit(_ node: AwaitExprSyntax) -> ExprSyntax {
    let hadTryBefore = node.expression.is(TryExprSyntax.self)
    let visited = super.visit(node)
    guard let awaitNode = visited.as(AwaitExprSyntax.self),
          !hadTryBefore,
          let tryExpr = awaitNode.expression.as(TryExprSyntax.self) else { return visited }
    var newAwait = awaitNode.with(\.expression, tryExpr.expression)
    newAwait.awaitKeyword = newAwait.awaitKeyword.with(\.leadingTrivia, [])
    return ExprSyntax(TryExprSyntax(
        tryKeyword: tryExpr.tryKeyword.with(\.leadingTrivia, awaitNode.awaitKeyword.leadingTrivia),
        expression: ExprSyntax(newAwait)))
}
```

The `hadTryBefore` guard prevents reordering pre-existing `await try` that the outer visitor still needs to process.

## Removing Force-Unwrap Token (try!/as!)

When setting `TryExprSyntax.questionOrExclamationMark = nil`, the `!` token's trailing trivia (usually a space) is lost. Transfer it to `tryKeyword.trailingTrivia`:

```swift
let bangTrivia = tryNode.questionOrExclamationMark?.trailingTrivia ?? .space
return ExprSyntax(
    tryNode
        .with(\.questionOrExclamationMark, nil)
        .with(\.tryKeyword, tryNode.tryKeyword.with(\.trailingTrivia, bangTrivia))
)
```

Without this, `try! foo()` becomes `tryfoo()` instead of `try foo()`.

Used by: `NoForceTryInTests`.

## Adding Effect Specifiers (throws/async)

When adding `throws` to a function that doesn't have it, the space before `{` lives on `body.leftBrace.leadingTrivia`. Transfer it to the new `throws` keyword and give `{` a fresh space:

```swift
var tc = ThrowsClauseSyntax(throwsSpecifier: .keyword(.throws, trailingTrivia: []))
if var body = result.body {
    tc.throwsSpecifier.leadingTrivia = body.leftBrace.leadingTrivia
    body.leftBrace.leadingTrivia = .space
    result.body = body
}
result.signature.effectSpecifiers = FunctionEffectSpecifiersSyntax(throwsClause: tc)
```

**Common mistake**: Adding `leadingTrivia: .space` to `throws` while `{` keeps its own space → double space (`func foo()  throws {`). Always steal the `{` trivia.

Same pattern applies when `async` already exists — the space before `{` is still on `body.leftBrace.leadingTrivia`, not on `async.trailingTrivia`.

Used by: `NoForceTryInTests`.
