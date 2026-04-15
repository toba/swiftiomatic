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

## Replace MemberAccessExpr with DeclReferenceExpr (Remove Prefix)

Remove a prefix like `Self.` from `Self.bar()` by replacing `MemberAccessExprSyntax` with `DeclReferenceExprSyntax`:

```swift
public override func visit(_ node: MemberAccessExprSyntax) -> ExprSyntax {
    let visited = super.visit(node)
    guard let memberAccess = visited.as(MemberAccessExprSyntax.self) else { return visited }
    guard let base = memberAccess.base,
          let declRef = base.as(DeclReferenceExprSyntax.self),
          declRef.baseName.tokenKind == .keyword(.Self),
          memberAccess.declName.baseName.tokenKind != .keyword(.`init`)
    else { return visited }
    // ... context checks ...
    diagnose(.msg, on: base)
    var result = DeclReferenceExprSyntax(
        baseName: memberAccess.declName.baseName,
        argumentNames: memberAccess.declName.argumentNames)
    result.leadingTrivia = declRef.leadingTrivia
    result.trailingTrivia = memberAccess.declName.baseName.trailingTrivia
    return ExprSyntax(result)
}
```

This works because `MemberAccessExprSyntax` → `ExprSyntax` is the return type, and
`DeclReferenceExprSyntax` IS an `ExprSyntax`. Unlike covariant pattern returns (which fail
silently), expression-level node kind changes work reliably.

**Multiline `Self.bar()`**: when `Self` is on one line and `.bar()` on the next
(`Self\n    .bar()`), the `Self` token's leading trivia has the indentation. Transferring
it to the replacement `DeclReferenceExprSyntax` preserves formatting: just `bar()` with
the correct indentation.

Used by: `RedundantStaticSelf`.

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

## Chain-Top Wrapping (convert inner nodes, wrap at top)

When a rule converts expressions inside a chain (e.g., `!` → `?`) but needs to wrap at the chain's outermost boundary (e.g., `try XCTUnwrap(...)`), wrapping at the inner level produces wrong results because the chain extends above.

**Wrong**: visiting `ForceUnwrapExpr(foo!)` in `foo!.value` and wrapping → `try XCTUnwrap(foo).value`
**Right**: convert inner to `?`, wrap at chain top → `try XCTUnwrap(foo?.value)`

**Architecture**: use a flag (`chainNeedsWrapping`) set at the inner level, consumed at the chain top:

```swift
private var chainNeedsWrapping = false

// Inner node: always convert, signal wrapping needed
public override func visit(_ node: ForceUnwrapExprSyntax) -> ExprSyntax {
    let visited = super.visit(node)
    guard let typedNode = visited.as(ForceUnwrapExprSyntax.self) else { return visited }

    // If THIS node IS the chain top, wrap directly
    if isChainTop(Syntax(node)) {
        let context = classifyChainTopContext(Syntax(node))
        if context == .wrap {
            return wrapInUnwrap(typedNode.expression)
        }
        // .noWrap: just convert to ?
        return convertToOptionalChaining(typedNode)
    }

    // Not the chain top: convert to ?, set flag for chain top
    chainNeedsWrapping = true
    return convertToOptionalChaining(typedNode)
}

// Chain top nodes: save/restore flag, wrap if signaled
public override func visit(_ node: MemberAccessExprSyntax) -> ExprSyntax {
    let savedFlag = chainNeedsWrapping
    chainNeedsWrapping = false
    let visited = super.visit(node)
    let childFlag = chainNeedsWrapping
    chainNeedsWrapping = savedFlag || childFlag
    guard let typedNode = visited.as(MemberAccessExprSyntax.self) else { return visited }

    if isChainTop(Syntax(node)) && childFlag {
        return wrapIfNeeded(ExprSyntax(typedNode), originalNode: Syntax(node))
    }
    return ExprSyntax(typedNode)
}
```

**`isChainTop` must include ALL chain node types** — missing any causes premature wrapping:

```swift
private func isChainTop(_ node: Syntax) -> Bool {
    guard let parent = node.parent else { return true }
    if parent.is(MemberAccessExprSyntax.self) { return false }
    if parent.is(ForceUnwrapExprSyntax.self) { return false }
    if parent.is(OptionalChainingExprSyntax.self) { return false }
    if let f = parent.as(FunctionCallExprSyntax.self), f.calledExpression.id == node.id { return false }
    if let s = parent.as(SubscriptCallExprSyntax.self), s.calledExpression.id == node.id { return false }
    return true
}
```

**Context classification uses three states**: `.wrap`, `.noWrap`, `.propagate`. Use `.propagate` when the boundary isn't the real wrapping point (e.g., inside `TupleExprSyntax`).

**Override chain top visitors**: `MemberAccessExprSyntax`, `FunctionCallExprSyntax`, `SubscriptCallExprSyntax`. Each uses the save/restore/check pattern above.

Used by: `NoForceUnwrap`.

## Assignment operator is AssignmentExprSyntax

After operator folding (`operatorTable.foldAll`), `=` produces `InfixOperatorExprSyntax` with `operator: AssignmentExprSyntax`, NOT `BinaryOperatorExprSyntax`. Check both:

```swift
let op = infixExpr.operator
if op.is(AssignmentExprSyntax.self) { /* assignment */ }
if let binOp = op.as(BinaryOperatorExprSyntax.self) { /* ==, +, etc. */ }
```

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

Used by: `NoForceTry`.

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

Used by: `NoForceTry`.

## Trivia Transfer When Replacing Expressions

When replacing a `FunctionCallExprSyntax` (e.g., `XCTAssert(x)`) with a new expression (e.g., `#expect(x)`), the replacement has no trivia — the original's indentation is lost:

```swift
// WRONG: #expect(x) has no leading trivia → loses indentation
if var replacement = buildExpectMacro(args) {
    return replacement  // output: "#expect(x)" with no indent
}

// RIGHT: transfer trivia from the original
if var replacement = buildExpectMacro(args) {
    replacement.leadingTrivia = typedNode.leadingTrivia
    replacement.trailingTrivia = typedNode.trailingTrivia
    return replacement
}
```

The leading trivia of the first token in an expression carries the line's indentation. Newly constructed syntax nodes have empty trivia. Always transfer from the original.

Used by: `PreferSwiftTesting` (assertion conversion).

## Removing Inheritance Clause

`InheritanceClauseSyntax.removing(named:)` returns:
- `nil` → item removed, list now empty (caller should set `inheritanceClause = nil`)
- `self` → name not found (same count, no change)
- Modified clause → item removed, others remain

When setting `inheritanceClause = nil`, the space before `{` (which was trailing trivia on the last inherited type) is lost. Fix by adding space to `memberBlock.leftBrace.leadingTrivia`:

```swift
if let newClause = inheritanceClause.removing(named: "XCTestCase") {
    if newClause.inheritedTypes.count == inheritanceClause.inheritedTypes.count {
        // Not found — no change
    } else {
        result.inheritanceClause = newClause
    }
} else {
    // Removed and empty — drop entire clause, fix space before {
    result.inheritanceClause = nil
    result.memberBlock.leftBrace.leadingTrivia = .space
}
```

Used by: `PreferSwiftTesting`.

## Replacing Declaration Types (func → init/deinit)

When converting `override func setUp()` → `init()`, removing the `override` modifier loses its leading trivia (blank line + indentation). Use the **original** node's leading trivia, not the visited result:

```swift
private func convertSetUp(_ node: FunctionDeclSyntax) -> DeclSyntax {
    let visited = super.visit(node)
    guard var result = visited.as(FunctionDeclSyntax.self) else { return visited }

    // Remove override
    result.modifiers = result.modifiers.filter { $0.name.tokenKind != .keyword(.override) }

    let initDecl = InitializerDeclSyntax(
        attributes: result.attributes,
        modifiers: result.modifiers,
        initKeyword: .keyword(.init,
            leadingTrivia: node.leadingTrivia,  // ← ORIGINAL node, not result
            trailingTrivia: []),
        signature: result.signature,  // ← reuse original to preserve trivia
        body: result.body)
    return DeclSyntax(initDecl)
}
```

**Key pitfalls**:
- `result.leadingTrivia` after removing `override` is the **func** keyword's leading trivia (just a space), not the declaration's (blank line + indent)
- Building a new `FunctionParameterClauseSyntax` loses trivia on `)` → `init(){` with no space. Reuse `result.signature` instead
- For `deinit`, there are no parens — set `deinitKeyword.trailingTrivia` to the space before `{`

Used by: `PreferSwiftTesting` (setUp→init, tearDown→deinit).

## Unwrapping try/await Layers

When searching for a function call inside a code block item, the call may be wrapped in `try`, `await`, or both. Use recursive unwrapping:

```swift
private func extractFunctionCall(from item: CodeBlockItemSyntax.Item) -> FunctionCallExprSyntax? {
    func unwrapToCall(_ expr: ExprSyntax) -> FunctionCallExprSyntax? {
        if let call = expr.as(FunctionCallExprSyntax.self) { return call }
        if let tryExpr = expr.as(TryExprSyntax.self) { return unwrapToCall(tryExpr.expression) }
        if let awaitExpr = expr.as(AwaitExprSyntax.self) { return unwrapToCall(awaitExpr.expression) }
        return nil
    }
    if let call = item.as(FunctionCallExprSyntax.self) { return call }
    if let tryExpr = item.as(TryExprSyntax.self) { return unwrapToCall(tryExpr.expression) }
    if let awaitExpr = item.as(AwaitExprSyntax.self) { return unwrapToCall(awaitExpr.expression) }
    return nil
}
```

Without this, `try await super.setUp()` won't be detected for removal.

Used by: `PreferSwiftTesting` (super.setUp/tearDown removal).

## File-Level Bail-Out Pattern

Rules that transform entire files (e.g., XCTest→Swift Testing migration) should pre-scan for unsupported patterns in `visit(SourceFileSyntax)` before calling `super.visit()`:

```swift
public override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
    // Pre-scan: detect imports, collect type names, check for unsupported patterns
    guard hasXCTestImport else { return node }  // no-op if not applicable
    if hasUnsupportedPatterns(in: node) {
        bailOut = true
        return node  // return UNCHANGED — don't call super.visit
    }
    return super.visit(node)  // proceed with transformation
}
```

Scan for unsupported identifiers (`expectation`, `wait`, `measure`, etc.) via `node.tokens(viewMode: .sourceAccurate)`. Check for async/throws tearDown, unknown overrides, XCTestCase extensions separately.

Used by: `PreferSwiftTesting`.

## Scope Tracking with Rewriter State

Format rules that need context (inside test function, inside XCTestCase, etc.) use private instance variables with save/restore:

```swift
private var insideXCTestCase = false

public override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
    let wasInside = insideXCTestCase
    if isXCTestCase(node) { insideXCTestCase = true }
    defer { insideXCTestCase = wasInside }
    return super.visit(node)  // children see the flag
}
```

**Critical**: always save before, restore in `defer`. Without save/restore, nested types break (inner class resets the flag for the outer class).

For boolean flags propagated through the tree (like `chainNeedsWrapping`), use the save/restore/merge pattern: save → reset → super.visit → capture child value → restore with merge. See Chain-Top Wrapping above.

**Don't recurse into scope boundaries**: closures and nested functions create new scopes where `try` can't propagate. Return early without calling `super.visit`:

```swift
public override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
    ExprSyntax(node)  // don't recurse — try can't escape closures
}

public override func visit(_ node: StringLiteralExprSyntax) -> ExprSyntax {
    ExprSyntax(node)  // don't recurse — try not allowed in interpolation
}
```

Used by: `NoForceUnwrap`, `NoGuardInTests`, `PreferSwiftTesting`.
