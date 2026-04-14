# Format Rule Patterns: Lists, Statements, and File-Level Analysis

Recipes for list-level and file-level transformations: collapsing braces, splitting/merging lists, blank line manipulation, two-phase file analysis, cross-declaration matching, and import detection.

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

## File-Level Analysis (Two-Phase Rewriting)

When a rule's transformation depends on the entire file's structure (e.g., "is this the only type in the file?"), use a two-phase approach in `visit(_ node: SourceFileSyntax)`:

```swift
private var singleTypeName: String?
private var hasNestedTypes = false

public override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
    // Phase 1: Analyze — scan all top-level declarations
    analyzeFileStructure(node.statements)
    guard singleTypeName != nil, !hasNestedTypes else { return node }

    // Phase 2: Rewrite — transform members based on analysis
    var result = node
    result.statements = rewriteStatements(node.statements)
    return result
}
```

**Key patterns for Phase 1 (file structure analysis):**
- Iterate `CodeBlockItemListSyntax`, match `.decl` items
- Skip `ImportDeclSyntax` (always allowed)
- Recurse into `IfConfigDeclSyntax` clauses (`.statements` case)
- Extract type names: check `StructDeclSyntax`, `ClassDeclSyntax`, `EnumDeclSyntax`, `ActorDeclSyntax`, `ExtensionDeclSyntax`
- For extensions, distinguish simple names from nested: `extDecl.extendedType.as(IdentifierTypeSyntax.self)` — `Foo` matches, `Foo.Bar` (a `MemberTypeSyntax`) does not
- Any other declaration kind (top-level func, var, etc.) or statement invalidates the "single type" assumption

**Key patterns for Phase 2 (rewriting):**
- Don't use `SyntaxRewriter` visit methods — instead manually iterate `MemberBlockItemListSyntax`
- Only transform specific member types (func, var, init, subscript, typealias) — skip nested type declarations
- Use the generic `WithModifiersSyntax` protocol for modifier changes across all declaration types

**`#if` handling**: Both phases must recurse into `IfConfigDeclSyntax` — top-level declarations inside `#if` blocks are still file-scoped.

Used by: `RedundantFileprivate`.

### Cross-Declaration Matching and Removal

When Phase 1 collects types and Phase 2 matches them to related declarations (e.g., matching `EnvironmentKey` structs to `EnvironmentValues` extension properties), store the statement index during collection for later removal:

```swift
private struct KeyInfo {
    let name: String
    let statementIndex: Int  // index in CodeBlockItemListSyntax
}

// Phase 2: after transforming matched items, remove source declarations
let removedIndices = Set(matchedKeys.compactMap { keys[$0]?.statementIndex })
var filteredItems = [CodeBlockItemSyntax]()
var removedFirst = false
for (index, item) in items.enumerated() {
    if removedIndices.contains(index) {
        if index == 0 { removedFirst = true }
        continue
    }
    filteredItems.append(item)
}
// Strip leading whitespace if first item was removed
if removedFirst, var first = filteredItems.first {
    first.leadingTrivia = Trivia(pieces: first.leadingTrivia.drop {
        switch $0 {
        case .newlines, .carriageReturns, .carriageReturnLineFeeds, .spaces, .tabs: true
        default: false
        }
    })
    filteredItems[0] = first
}
```

**Token scanning for cross-references**: To find which key a property references, iterate tokens and match identifiers against collected names:

```swift
let keyName = varDecl.tokens(viewMode: .sourceAccurate).lazy
    .compactMap { token -> String? in
        guard case .identifier(let text) = token.tokenKind,
              keys[text] != nil else { return nil }
        return text
    }.first
```

Used by: `EnvironmentEntry`.

## Import Detection for Non-XCTest Frameworks

`context.importsXCTest` only covers XCTest. For other frameworks (e.g., `Testing`), use a private flag on the rule set during `visit(_ node: ImportDeclSyntax)`:

```swift
private var importsTesting = false

public override func visit(_ node: ImportDeclSyntax) -> DeclSyntax {
    if node.path.first?.name.text == "Testing" {
        importsTesting = true
    }
    return DeclSyntax(node)
}

// Then gate behavior in other visitors:
public override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
    guard importsTesting else { return DeclSyntax(node) }
    // ...
}
```

Format rules are `SyntaxRewriter` subclasses, so the import visitor fires before type-declaration visitors during tree rewriting. The flag is safe to use in subsequent visitors within the same file.

Used by: `RedundantSwiftTestingSuite`.
