import SwiftSyntax

/// Prefer `AnyObject` over `class` for class-constrained protocols.
///
/// The `class` keyword in protocol inheritance clauses was replaced by `AnyObject` in Swift 4.1.
/// Using `AnyObject` is the modern, preferred spelling.
///
/// Lint: A protocol inheriting from `class` instead of `AnyObject` raises a warning.
///
/// Format: `class` is replaced with `AnyObject` in the inheritance clause.
@_spi(Rules)
public final class AnyObjectProtocol: SyntaxFormatRule {

  public override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
    guard let inheritanceClause = node.inheritanceClause else {
      return DeclSyntax(node)
    }

    var foundViolation = false
    let newInheritedTypes = inheritanceClause.inheritedTypes.map { inherited -> InheritedTypeSyntax in
      guard let classRestriction = inherited.type.as(ClassRestrictionTypeSyntax.self) else {
        return inherited
      }

      foundViolation = true
      diagnose(.preferAnyObject, on: classRestriction.classKeyword)

      // Replace `class` with `AnyObject` identifier type, preserving trivia
      let anyObjectType = IdentifierTypeSyntax(
        name: .identifier(
          "AnyObject",
          leadingTrivia: classRestriction.classKeyword.leadingTrivia,
          trailingTrivia: classRestriction.classKeyword.trailingTrivia
        )
      )
      return inherited.with(\.type, TypeSyntax(anyObjectType))
    }

    guard foundViolation else {
      return DeclSyntax(node)
    }

    let newClause = inheritanceClause.with(
      \.inheritedTypes,
      InheritedTypeListSyntax(newInheritedTypes)
    )
    return DeclSyntax(node.with(\.inheritanceClause, newClause))
  }
}

extension Finding.Message {
  fileprivate static let preferAnyObject: Finding.Message =
    "use 'AnyObject' instead of 'class' for class-constrained protocols"
}
