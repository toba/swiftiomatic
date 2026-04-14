# Format Rule Patterns

Recipes for common format rule transformations. Each pattern shows the visitor structure, AST manipulation, and trivia handling.

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

## Remove Entire Declarations

Visit the **list type** and filter:

```swift
public override func visit(_ node: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
    let visited = super.visit(node)
    var newItems = [CodeBlockItemSyntax]()
    var changed = false
    var removedFirst = false

    for (index, item) in visited.enumerated() {
      if shouldRemove(item) {
        diagnose(.myMessage, on: item)
        changed = true
        if index == 0 { removedFirst = true }
        continue
      }
      newItems.append(item)
    }

    guard changed else { return visited }

    // Strip leading whitespace from new first item
    if removedFirst, var first = newItems.first {
      first.leadingTrivia = Trivia(pieces: first.leadingTrivia.drop {
        switch $0 {
        case .newlines, .carriageReturns, .carriageReturnLineFeeds, .spaces, .tabs: true
        default: false
        }
      })
      newItems[0] = first
    }
    return CodeBlockItemListSyntax(newItems)
}
```

## Stateful Member Rewriting

Transform extension members differently based on extension context:

```swift
private enum State { case topLevel, insideExtension(accessKeyword: Keyword) }
private var state: State = .topLevel

public override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
    self.state = .insideExtension(accessKeyword: .public)
    defer { self.state = .topLevel }
    var result = super.visit(node).as(ExtensionDeclSyntax.self)!
    return DeclSyntax(result)
}

public override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
    guard case .insideExtension(let keyword) = state else { return DeclSyntax(node) }
    // modify member based on state
}
```

**Trivia when removing a modifier**: Save leading trivia before removing, apply to next token:

```swift
let savedLeadingTrivia = accessModifier.leadingTrivia
result.modifiers.remove(anyOf: [keyword])
if var firstModifier = result.modifiers.first {
    firstModifier.leadingTrivia = savedLeadingTrivia
    result.modifiers[result.modifiers.startIndex] = firstModifier
} else {
    result[keyPath: declKeywordKeyPath].leadingTrivia = savedLeadingTrivia
}
```

## Brace Collapsing

Collapse `{ }` → `{}` with a generic key-path helper:

```swift
private func collapseIfNeeded<Node: SyntaxProtocol>(
    _ node: Node,
    leftBrace: WritableKeyPath<Node, TokenSyntax>,
    rightBrace: WritableKeyPath<Node, TokenSyntax>
) -> Node {
    let left = node[keyPath: leftBrace]
    let right = node[keyPath: rightBrace]
    if left.trailingTrivia.hasAnyComments || right.leadingTrivia.hasAnyComments { return node }
    guard !left.trailingTrivia.isEmpty || !right.leadingTrivia.isEmpty else { return node }
    diagnose(.myMessage, on: left)
    var result = node
    result[keyPath: leftBrace] = left.with(\.trailingTrivia, [])
    result[keyPath: rightBrace] = right.with(\.leadingTrivia, [])
    return result
}
```

## Split Lists (1→N)

Split a single item into multiple (e.g., `&&` conditions, semicolons):

```swift
public override func visit(_ node: ConditionElementListSyntax) -> ConditionElementListSyntax {
    let visited = super.visit(node)
    var newItems = [ConditionElementSyntax]()
    for item in visited {
        if let splits = trySplit(item) {
            diagnose(.msg, on: item)
            newItems.append(contentsOf: splits)
        } else {
            newItems.append(item)
        }
    }
    return ConditionElementListSyntax(newItems)
}
```

Used by: `DoNotUseSemicolons`, `OneVariableDeclarationPerLine`, `OneCasePerLine`, `AndOperator`.

## Merge Adjacent Statements (N→1)

Windowed iteration over a list:

```swift
public override func visit(_ node: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
    let visited = super.visit(node)
    let items = Array(visited)
    var newItems = [CodeBlockItemSyntax]()
    var i = 0
    while i < items.count {
        if i + 1 < items.count, let merged = tryMerge(items[i], items[i + 1]) {
            diagnose(.msg, on: items[i])
            newItems.append(merged)
            i += 2
        } else {
            newItems.append(items[i])
            i += 1
        }
    }
    return CodeBlockItemListSyntax(newItems)
}
```

## Remove Modifiers Across Declaration Types

Generic helper avoids duplicating logic across 10+ visit overrides:

```swift
private func removeRedundantX<Decl: DeclSyntaxProtocol & WithModifiersSyntax>(
    from decl: Decl, keywordKeyPath: WritableKeyPath<Decl, TokenSyntax>
) -> Decl {
    guard let modifier = decl.modifiers.accessLevelModifier,
          modifier.name.tokenKind == .keyword(.internal) else { return decl }
    diagnose(.msg, on: modifier.name)
    var result = decl
    let savedTrivia = modifier.leadingTrivia
    result.modifiers.remove(anyOf: [.internal])
    if result.modifiers.first != nil {
        result.modifiers[result.modifiers.startIndex].leadingTrivia = savedTrivia
    } else {
        result[keyPath: keywordKeyPath].leadingTrivia = savedTrivia
    }
    return result
}

// Each override is mechanical:
public override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
    DeclSyntax(removeRedundantX(from: node, keywordKeyPath: \.funcKeyword))
}
public override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
    let visited = super.visit(node).cast(ClassDeclSyntax.self)
    return DeclSyntax(removeRedundantX(from: visited, keywordKeyPath: \.classKeyword))
}
```

## Remove Attributes Across Declaration Types

Generic helper using `AttributeListSyntax+Convenience` and `WithAttributesSyntax` protocol:

```swift
private func removeRedundantFoo<Decl: DeclSyntaxProtocol & WithAttributesSyntax>(
    from decl: Decl
) -> Decl {
    guard let fooAttr = decl.attributes.attribute(named: "foo") else { return decl }
    guard fooAttr.arguments == nil else { return decl }  // skip @foo(args)
    guard shouldRemove(decl) else { return decl }
    diagnose(.msg, on: fooAttr)
    var result = decl
    result.attributes = decl.attributes.removing(named: "foo")
    return result
}

// Thin visit overrides:
public override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
    DeclSyntax(removeRedundantFoo(from: node))
}
public override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
    let visited = super.visit(node).cast(ClassDeclSyntax.self)
    return DeclSyntax(removeRedundantFoo(from: visited))
}
```

`removing(named:)` transfers trivia from the removed attribute to the next kept element. When the removed attribute is the **only** attribute (list becomes empty), the caller must transfer trivia to the declaration keyword or next modifier — same pattern as `Remove Modifiers` above:

```swift
let savedTrivia = fooAttr.leadingTrivia
result.attributes = decl.attributes.removing(named: "foo")
if result.attributes.isEmpty {
    if result.modifiers.first != nil {
        result.modifiers[result.modifiers.startIndex].leadingTrivia = savedTrivia
    } else {
        result[keyPath: keywordKeyPath].leadingTrivia = savedTrivia
    }
}
```

Use `super.visit` for container types (class/struct/enum) that may have nested declarations.

Used by: `RedundantObjc`, `RedundantViewBuilder`.

## Remove Type Specifiers

Remove `borrowing`/`consuming` from `AttributedTypeSyntax`:

```swift
public override func visit(_ node: AttributedTypeSyntax) -> TypeSyntax {
    let visited = super.visit(node)
    guard let attributed = visited.as(AttributedTypeSyntax.self) else { return visited }
    let remaining = attributed.specifiers.filter { /* keep non-target specifiers */ }
    if remaining.isEmpty && attributed.attributes.isEmpty && attributed.lateSpecifiers.isEmpty {
        var base = attributed.baseType
        base.leadingTrivia = attributed.leadingTrivia
        base.trailingTrivia = attributed.trailingTrivia
        return TypeSyntax(base)
    }
    return TypeSyntax(attributed.with(\.specifiers, TypeSpecifierListSyntax(remaining)))
}
```

**Ownership modifiers location**: In parameter types (`func foo(_ bar: consuming Bar)`), `consuming`/`borrowing` live in `AttributedTypeSyntax.specifiers`. On function declarations (`consuming func move()`), they're in `DeclModifierSyntax`. Handle both.

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

## Multi-Property Declaration Modification

Modify multiple properties (e.g., generic params + where clause) with key-path helpers:

```swift
private func simplifyConstraints<D>(
    _ decl: D,
    genericParamsKeyPath: WritableKeyPath<D, GenericParameterClauseSyntax?>,
    whereClauseKeyPath: WritableKeyPath<D, GenericWhereClauseSyntax?>
) -> D {
    guard var params = decl[keyPath: genericParamsKeyPath],
          let whereClause = decl[keyPath: whereClauseKeyPath] else { return decl }
    // modify params, rebuild or remove whereClause
    var result = decl
    result[keyPath: genericParamsKeyPath] = params
    result[keyPath: whereClauseKeyPath] = remainingReqs.isEmpty ? nil : rebuiltClause
    return result
}
```

**Partial where clause rebuild** — strip first requirement's leading trivia (`where` keyword provides the space):

```swift
var newReqs = [GenericRequirementSyntax]()
for (i, req) in remainingRequirements.enumerated() {
    var r = req
    if i == 0 { r.leadingTrivia = [] }
    if i == remainingRequirements.count - 1 { r.trailingComma = nil }
    newReqs.append(r)
}
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

## Insert / Remove Blank Lines Between Statements

Rules like `BlankLineAfterImports`, `BlankLineAfterSwitchCase`, `BlankLinesAfterGuardStatements` manipulate blank lines by adjusting the leading trivia of the *next* statement.

**Insert a blank line**: Prepend `.newline` to the next statement's leading trivia:

```swift
var modifiedNext = nextStmt
modifiedNext.leadingTrivia = .newline + nextStmt.leadingTrivia
statements[nextIndex] = modifiedNext
```

**Remove blank lines**: Replace the first `.newlines(N)` piece with `.newlines(1)`:

```swift
var pieces = Array(statement.leadingTrivia.pieces)
for (i, piece) in pieces.enumerated() {
    if case .newlines = piece {
        pieces[i] = .newlines(1)
        break
    }
}
result.leadingTrivia = Trivia(pieces: pieces)
```

**Count blank lines** (only before first comment — see trivia-and-testing.md):

```swift
var newlines = 0
for piece in trivia.pieces {
    if case .newlines(let n) = piece { newlines += n }
    else if piece.isSpaceOrTab { continue }
    else { break }
}
return max(0, newlines - 1)  // -1 for end-of-previous-line newline
```

**Key patterns**:
- `SourceFileSyntax` for file-level rules (imports)
- `SwitchExprSyntax` for switch case spacing (iterate `cases: SwitchCaseListSyntax`, check `rightBrace` for trailing blank)
- `CodeBlockSyntax` for statement-level rules (guards) — `super.visit` handles nested scopes
- Always keep `originalStatements` for `diagnose()` targets (see trivia-and-testing.md § Position Shift)
- `SwitchCaseListSyntax.Element` is an enum: `.switchCase(SwitchCaseSyntax)` | `.ifConfigDecl(IfConfigDeclSyntax)`

Used by: `BlankLineAfterImports`, `BlankLineAfterSwitchCase`, `BlankLinesAfterGuardStatements`.
