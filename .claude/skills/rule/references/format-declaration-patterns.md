# Format Rule Patterns: Declarations

Recipes for declaration-level format rule transformations: removing, adding, and modifying declarations, modifiers, attributes, inheritance, and type specifiers.

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

**Conditional attribute removal** — when only certain `@Foo` should be removed (e.g., `@Suite` without args but not `@Suite(.serialized)`), use `attribute(named:)` to find, check arguments, then `remove(named:)`:

```swift
guard let attr = node.attributes.attribute(named: "Suite"),
      isRedundant(attr) else { return node }
diagnose(.msg, on: attr)
var result = node
let savedTrivia = attr.leadingTrivia
result.attributes.remove(named: "Suite")
if result.attributes.isEmpty {
    result[keyPath: keywordKeyPath].leadingTrivia = savedTrivia
}
```

**Attribute argument checking**: `attr.arguments == nil` means no parens at all. `case let .argumentList(args) = attr.arguments, args.isEmpty` means empty `()`. Both are distinct from `@Foo(value)`.

Used by: `RedundantObjc`, `RedundantViewBuilder`, `RedundantSwiftTestingSuite`.

## Add Attributes to a Declaration

Prepend an attribute (e.g., `@Entry`) by saving leading trivia from the first existing token, inserting into `attributes`, and clearing the old leading trivia:

```swift
private func addAttribute(named name: String, to varDecl: VariableDeclSyntax) -> VariableDeclSyntax {
    var result = varDecl
    let savedTrivia: Trivia
    if let firstModifier = result.modifiers.first {
        savedTrivia = firstModifier.leadingTrivia
        result.modifiers[result.modifiers.startIndex] =
            firstModifier.with(\.leadingTrivia, [])
    } else {
        savedTrivia = result.bindingSpecifier.leadingTrivia
        result.bindingSpecifier = result.bindingSpecifier.with(\.leadingTrivia, [])
    }
    let attr = AttributeSyntax(
        atSign: .atSignToken(leadingTrivia: savedTrivia),
        attributeName: IdentifierTypeSyntax(
            name: TokenSyntax(.identifier(name), trailingTrivia: .space, presence: .present)
        )
    )
    var elements = Array(result.attributes)
    elements.insert(AttributeListSyntax.Element(attr), at: 0)
    result.attributes = AttributeListSyntax(elements)
    return result
}
```

**Key points**: `atSign` gets the saved leading trivia (indent/newlines). The identifier gets `trailingTrivia: .space` to separate from the next token. `AttributeListSyntax.Element(attr)` wraps the attribute for insertion.

Used by: `EnvironmentEntry`.

## Remove Inheritance Conformance

Remove a type from the inheritance clause (e.g., `: Sendable`):

```swift
public override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
    let visited = super.visit(node).cast(StructDeclSyntax.self)
    guard let inheritanceClause = visited.inheritanceClause,
          let inherited = inheritanceClause.inherited(named: "Sendable")
    else { return DeclSyntax(visited) }
    diagnose(.msg, on: inherited)
    var result = visited
    let newClause = inheritanceClause.removing(named: "Sendable")
    result.inheritanceClause = newClause
    if newClause == nil {
        // Entire clause removed — space before `{` was in the removed type's trailing trivia.
        result.memberBlock.leftBrace.leadingTrivia = .space
    }
    return DeclSyntax(result)
}
```

**Trivia pitfall**: When the last conformance is removed, `removing(named:)` returns `nil`. Setting `inheritanceClause = nil` drops the `:` token and all type trivia. The space before `{` (which lived in the last type's trailing trivia) is lost. Fix: explicitly set `memberBlock.leftBrace.leadingTrivia = .space`.

`removing(named:)` handles comma cleanup and trailing trivia transfer for partial removals automatically.

Used by: `RedundantSendable`.

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

## Generic Parameter and Where Clause Removal

When removing generic parameters and where clause requirements (e.g., converting `<T: Protocol>` to `some Protocol`), rebuild the lists with proper commas and trivia:

```swift
private func rebuildGenericClause(
    _ clause: GenericParameterClauseSyntax,
    removing indices: Set<Int>
) -> GenericParameterClauseSyntax? {
    let remaining = clause.parameters.enumerated()
        .filter { !indices.contains($0.offset) }.map(\.element)
    if remaining.isEmpty { return nil }
    let newParams = remaining.enumerated().map { i, param -> GenericParameterSyntax in
        var p = param
        p.trailingComma = i < remaining.count - 1
            ? .commaToken(trailingTrivia: .space) : nil
        if i == 0 { p.leadingTrivia = [] }
        return p
    }
    var result = clause
    result.parameters = GenericParameterListSyntax(newParams)
    return result
}
```

Same pattern for `GenericRequirementListSyntax`. Returning `nil` from the rebuild removes the clause entirely.

## Static Context Detection

Walk the parent chain to determine if code is inside a `static`/`class` member. **Key pitfall**: nested functions inside a static method are still in a static context, so don't stop at non-static `FunctionDeclSyntax` — only stop at direct type members.

```swift
private func isInStaticContext(_ node: some SyntaxProtocol) -> Bool {
    var current = node.parent
    while let parent = current {
        if let funcDecl = parent.as(FunctionDeclSyntax.self) {
            if funcDecl.modifiers.contains(anyOf: [.static, .class]) { return true }
            // Direct member of a type → instance method, not static
            if funcDecl.parent?.is(MemberBlockItemSyntax.self) == true { return false }
            // Nested function → continue walking up
        }
        if let varDecl = parent.as(VariableDeclSyntax.self) {
            if varDecl.modifiers.contains(anyOf: [.static, .class]) { return true }
            if varDecl.parent?.is(MemberBlockItemSyntax.self) == true { return false }
        }
        // Initializers are NOT static context
        if parent.is(InitializerDeclSyntax.self) { return false }
        // Stop at type boundaries
        if parent.is(ClassDeclSyntax.self) || parent.is(StructDeclSyntax.self)
            || parent.is(EnumDeclSyntax.self) || parent.is(ActorDeclSyntax.self) { return false }
        current = parent.parent
    }
    return false
}
```

**`MemberBlockItemSyntax` check**: distinguishes direct type members from nested declarations. `func bar()` inside `static func foo()` has parent `CodeBlockItemSyntax`, not `MemberBlockItemSyntax`.

Used by: `RedundantStaticSelf`.

## Remove Type Annotation with Comment Preservation

When removing a type annotation (`let x: T = expr` → `let x = expr`), the type's trailing trivia may contain block comments that must be transferred to the `=` token:

```swift
var newBinding = binding
newBinding.typeAnnotation = nil

var newInitializer = initializer
let typeTrailingTrivia = typeAnnotation.type.trailingTrivia
if typeTrailingTrivia.hasAnyComments {
    // Transfer comment: `var x: T /* c */ = val` → `var x /* c */ = val`
    newInitializer.equal.leadingTrivia = typeTrailingTrivia
} else if initializer.equal.leadingTrivia.isEmpty {
    newInitializer.equal.leadingTrivia = .space
}
newBinding.initializer = newInitializer
```

Without this, `var x: UIView /* view */ = UIView()` would lose the `/* view */` comment.

Used by: `RedundantType`.

**Where clause removal trivia**: When removing the where clause, the space that was before `where` (typically on the preceding token's trailing trivia) remains, and the space before `{` (on the where clause's last token) is lost. Fix by: (1) set `body.leftBrace.leadingTrivia = .space`, (2) strip trailing trivia from the preceding token (return clause type or parameter `)`):

```swift
if result.genericWhereClause == nil, visited.genericWhereClause != nil {
    if var body = result.body {
        body.leftBrace.leadingTrivia = .space
        result.body = body
    }
    if let returnClause = result.signature.returnClause {
        result.signature.returnClause = returnClause.with(
            \.type, returnClause.type.with(\.trailingTrivia, []))
    } else {
        result.signature.parameterClause.rightParen =
            result.signature.parameterClause.rightParen.with(\.trailingTrivia, [])
    }
}
```

Used by: `OpaqueGenericParameters`, `SimplifyGenericConstraints`.
