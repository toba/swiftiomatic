import SwiftSyntax

/// Remove explicit `borrowing` and `consuming` ownership modifiers.
///
/// Ownership modifiers are an advanced feature that most code does not need. When present
/// on function declarations (e.g. `consuming func move()`) or parameter types
/// (e.g. `func foo(_ bar: consuming Bar)`), they are removed.
///
/// Lint: If an explicit `borrowing` or `consuming` modifier is found, a lint warning is raised.
///
/// Format: The ownership modifier is removed.
final class NoExplicitOwnership: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }

  override class var defaultValue: BasicRuleValue { BasicRuleValue(rewrite: false, lint: .no) }

  private static let ownershipKeywords: Set<Keyword> = [.borrowing, .consuming]

  // MARK: - Declaration modifiers (e.g. `consuming func move()`)

  override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
    // Must call super.visit to recurse into parameter types where AttributedTypeSyntax lives.
    let visited = super.visit(node).cast(FunctionDeclSyntax.self)
    return DeclSyntax(removingOwnershipModifier(from: visited, keywordKeyPath: \.funcKeyword))
  }

  // MARK: - Type specifiers (e.g. `consuming Foo` in parameter types)

  override func visit(_ node: AttributedTypeSyntax) -> TypeSyntax {
    let visited = super.visit(node)
    guard let attributed = visited.as(AttributedTypeSyntax.self) else { return visited }

    let ownershipIndices = attributed.specifiers.enumerated().compactMap { index, element -> Int? in
      guard case .simpleTypeSpecifier(let simple) = element,
            case .keyword(let kw) = simple.specifier.tokenKind,
            Self.ownershipKeywords.contains(kw)
      else { return nil }
      return index
    }
    guard !ownershipIndices.isEmpty else { return visited }

    // Diagnose each ownership specifier.
    for index in ownershipIndices {
      if case .simpleTypeSpecifier(let simple) = attributed.specifiers[
        attributed.specifiers.index(attributed.specifiers.startIndex, offsetBy: index)
      ] {
        diagnose(.removeOwnershipModifier(keyword: simple.specifier.text), on: simple.specifier)
      }
    }

    // Remove ownership specifiers.
    let ownershipSet = Set(ownershipIndices)
    let remaining = attributed.specifiers.enumerated().filter { !ownershipSet.contains($0.offset) }
      .map(\.element)

    // If nothing remains besides the base type, unwrap.
    if remaining.isEmpty && attributed.attributes.isEmpty && attributed.lateSpecifiers.isEmpty {
      var base = attributed.baseType
      base.leadingTrivia = attributed.leadingTrivia
      base.trailingTrivia = attributed.trailingTrivia
      return TypeSyntax(base)
    }

    var result = attributed
    result.specifiers = TypeSpecifierListSyntax(remaining)
    return TypeSyntax(result)
  }

  // MARK: - Helper

  private func removingOwnershipModifier<Decl: DeclSyntaxProtocol & WithModifiersSyntax>(
    from decl: Decl,
    keywordKeyPath: WritableKeyPath<Decl, TokenSyntax>
  ) -> Decl {
    guard let ownershipModifier = decl.modifiers.first(where: { modifier in
      guard case .keyword(let kw) = modifier.name.tokenKind else { return false }
      return Self.ownershipKeywords.contains(kw)
    }) else {
      return decl
    }

    diagnose(.removeOwnershipModifier(keyword: ownershipModifier.name.text), on: ownershipModifier.name)
    return decl.removingModifiers(Self.ownershipKeywords, keyword: keywordKeyPath)
  }
}

extension Finding.Message {
  fileprivate static func removeOwnershipModifier(keyword: String) -> Finding.Message {
    "remove explicit '\(keyword)' ownership modifier"
  }
}
