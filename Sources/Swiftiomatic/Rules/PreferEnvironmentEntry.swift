import SwiftSyntax

/// Use `@Entry` macro for `EnvironmentValues` instead of manual `EnvironmentKey` conformance.
///
/// Recognizes `EnvironmentKey`-conforming structs/enums paired with `EnvironmentValues` extension
/// properties and replaces them with `@Entry var` declarations.
///
/// Lint: A lint warning is raised when an `EnvironmentKey` property can be replaced with `@Entry`.
///
/// Format: The `EnvironmentKey` type is removed and the property is replaced with `@Entry var`.
final class PreferEnvironmentEntry: SyntaxFormatRule {

  static let isOptIn = true

  // MARK: - Types

  private struct KeyInfo {
    let name: String
    let defaultValue: DefaultValue?
    let statementIndex: Int
  }

  private enum DefaultValue {
    case expression(ExprSyntax)
    case closureBody(statements: CodeBlockItemListSyntax, rightBraceTrivia: Trivia)
  }

  // MARK: - State

  private var environmentKeys: [String: KeyInfo] = [:]
  private var matchedKeys: Set<String> = []

  // MARK: - Visitor

  override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
    collectEnvironmentKeys(from: node.statements)
    guard !environmentKeys.isEmpty else { return node }

    let newStatements = rewriteStatements(node.statements)
    guard !matchedKeys.isEmpty else { return node }

    var result = node
    result.statements = newStatements
    return result
  }

  // MARK: - Phase 1: Collect EnvironmentKey types

  private func collectEnvironmentKeys(from statements: CodeBlockItemListSyntax) {
    for (index, item) in statements.enumerated() {
      guard case .decl(let decl) = item.item else { continue }
      if let structDecl = decl.as(StructDeclSyntax.self) {
        collectIfEnvironmentKey(
          name: structDecl.name.text,
          inheritanceClause: structDecl.inheritanceClause,
          members: structDecl.memberBlock.members,
          statementIndex: index
        )
      } else if let enumDecl = decl.as(EnumDeclSyntax.self) {
        collectIfEnvironmentKey(
          name: enumDecl.name.text,
          inheritanceClause: enumDecl.inheritanceClause,
          members: enumDecl.memberBlock.members,
          statementIndex: index
        )
      }
    }
  }

  private func collectIfEnvironmentKey(
    name: String,
    inheritanceClause: InheritanceClauseSyntax?,
    members: MemberBlockItemListSyntax,
    statementIndex: Int
  ) {
    guard let inheritanceClause,
          inheritanceClause.contains(named: "EnvironmentKey"),
          let onlyMember = members.firstAndOnly,
          let varDecl = onlyMember.decl.as(VariableDeclSyntax.self),
          let binding = varDecl.bindings.first,
          let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
          pattern.identifier.text == "defaultValue"
    else { return }

    environmentKeys[name] = KeyInfo(
      name: name,
      defaultValue: extractDefaultValue(from: binding),
      statementIndex: statementIndex
    )
  }

  private func extractDefaultValue(from binding: PatternBindingSyntax) -> DefaultValue? {
    // Case 1: Has initializer (= value)
    if let initializer = binding.initializer {
      return .expression(initializer.value.trimmed)
    }

    // Case 2: Has computed body (implicit getter)
    guard let accessorBlock = binding.accessorBlock else { return nil }

    switch accessorBlock.accessors {
    case .getter(let body):
      if let onlyItem = body.firstAndOnly {
        if case .expr(let expr) = onlyItem.item {
          return .expression(expr.trimmed)
        }
        if case .stmt(let stmt) = onlyItem.item,
           let returnStmt = stmt.as(ReturnStmtSyntax.self),
           let expr = returnStmt.expression {
          return .expression(expr.trimmed)
        }
      }
      // Multi-statement body: needs closure wrapping { ... }()
      return .closureBody(
        statements: body,
        rightBraceTrivia: accessorBlock.rightBrace.leadingTrivia
      )
    case .accessors:
      return nil
    }
  }

  // MARK: - Phase 2: Transform

  private func rewriteStatements(
    _ statements: CodeBlockItemListSyntax
  ) -> CodeBlockItemListSyntax {
    // Transform EnvironmentValues extension properties
    var items = Array(statements)
    for (index, item) in items.enumerated() {
      guard case .decl(let decl) = item.item,
            let extDecl = decl.as(ExtensionDeclSyntax.self),
            extDecl.extendedType.trimmedDescription == "EnvironmentValues"
      else { continue }

      let rewritten = rewriteEnvironmentValuesExtension(extDecl)
      items[index].item = .decl(DeclSyntax(rewritten))
    }

    guard !matchedKeys.isEmpty else { return CodeBlockItemListSyntax(items) }

    // Remove matched EnvironmentKey declarations
    let removedIndices = Set(matchedKeys.compactMap { environmentKeys[$0]?.statementIndex })
    var filteredItems = [CodeBlockItemSyntax]()
    var removedFirst = false

    for (index, item) in items.enumerated() {
      if removedIndices.contains(index) {
        if index == 0 { removedFirst = true }
        continue
      }
      filteredItems.append(item)
    }

    // Strip leading whitespace from new first item if old first was removed
    if removedFirst, var first = filteredItems.first {
      first.leadingTrivia = Trivia(pieces: first.leadingTrivia.drop {
        switch $0 {
        case .newlines, .carriageReturns, .carriageReturnLineFeeds, .spaces, .tabs: true
        default: false
        }
      })
      filteredItems[0] = first
    }

    return CodeBlockItemListSyntax(filteredItems)
  }

  private func rewriteEnvironmentValuesExtension(
    _ extDecl: ExtensionDeclSyntax
  ) -> ExtensionDeclSyntax {
    let newMembers = extDecl.memberBlock.members.map { member -> MemberBlockItemSyntax in
      guard let varDecl = member.decl.as(VariableDeclSyntax.self),
            let rewritten = rewriteEnvironmentProperty(varDecl)
      else { return member }
      var result = member
      result.decl = DeclSyntax(rewritten)
      return result
    }
    var result = extDecl
    result.memberBlock.members = MemberBlockItemListSyntax(newMembers)
    return result
  }

  private func rewriteEnvironmentProperty(
    _ varDecl: VariableDeclSyntax
  ) -> VariableDeclSyntax? {
    guard let binding = varDecl.bindings.first,
          let accessorBlock = binding.accessorBlock,
          hasGetterAndSetter(accessorBlock)
    else { return nil }

    // Find which EnvironmentKey this property references
    let keyName = varDecl.tokens(viewMode: .sourceAccurate).lazy
      .compactMap { token -> String? in
        guard case .identifier(let text) = token.tokenKind,
              self.environmentKeys[text] != nil
        else { return nil }
        return text
      }
      .first

    guard let keyName, let keyInfo = environmentKeys[keyName] else { return nil }

    matchedKeys.insert(keyName)
    diagnose(.useEntryMacro, on: varDecl)

    // Build new binding: remove accessor, strip trailing space from type
    var newBinding = binding
    newBinding.accessorBlock = nil
    if var typeAnnotation = newBinding.typeAnnotation {
      typeAnnotation.type = typeAnnotation.type.trimmed
      newBinding.typeAnnotation = typeAnnotation
    }

    switch keyInfo.defaultValue {
    case .expression(let expr):
      newBinding.initializer = InitializerClauseSyntax(
        equal: .equalToken(leadingTrivia: .space, trailingTrivia: .space),
        value: ExprSyntax(expr)
      )
    case .closureBody(let statements, let rightBraceTrivia):
      let closure = ClosureExprSyntax(
        statements: statements,
        rightBrace: .rightBraceToken(leadingTrivia: rightBraceTrivia)
      )
      let call = FunctionCallExprSyntax(
        calledExpression: ExprSyntax(closure),
        leftParen: .leftParenToken(),
        arguments: [],
        rightParen: .rightParenToken()
      )
      newBinding.initializer = InitializerClauseSyntax(
        equal: .equalToken(leadingTrivia: .space, trailingTrivia: .space),
        value: ExprSyntax(call)
      )
    case nil:
      break
    }

    var result = varDecl
    result.bindings = PatternBindingListSyntax([newBinding])

    return addEntryAttribute(to: result)
  }

  private func hasGetterAndSetter(_ accessorBlock: AccessorBlockSyntax) -> Bool {
    guard case .accessors(let accessors) = accessorBlock.accessors else { return false }
    var hasGetter = false
    var hasSetter = false
    for accessor in accessors {
      switch accessor.accessorSpecifier.tokenKind {
      case .keyword(.get): hasGetter = true
      case .keyword(.set): hasSetter = true
      default: break
      }
    }
    return hasGetter && hasSetter
  }

  private func addEntryAttribute(to varDecl: VariableDeclSyntax) -> VariableDeclSyntax {
    var result = varDecl

    // Save leading trivia from the first significant token
    let savedTrivia: Trivia
    if let firstModifier = result.modifiers.first {
      savedTrivia = firstModifier.leadingTrivia
      result.modifiers[result.modifiers.startIndex] =
        firstModifier.with(\.leadingTrivia, [])
    } else {
      savedTrivia = result.bindingSpecifier.leadingTrivia
      result.bindingSpecifier = result.bindingSpecifier.with(\.leadingTrivia, [])
    }

    let entryAttr = AttributeSyntax(
      atSign: .atSignToken(leadingTrivia: savedTrivia),
      attributeName: IdentifierTypeSyntax(
        name: TokenSyntax(
          .identifier("Entry"), trailingTrivia: .space, presence: .present
        )
      )
    )

    var elements = Array(result.attributes)
    elements.insert(AttributeListSyntax.Element(entryAttr), at: 0)
    result.attributes = AttributeListSyntax(elements)

    return result
  }
}

extension Finding.Message {
  fileprivate static let useEntryMacro: Finding.Message =
    "use '@Entry' macro instead of manual 'EnvironmentKey' conformance"
}
