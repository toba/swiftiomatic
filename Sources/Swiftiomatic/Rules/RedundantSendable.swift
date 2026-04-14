import SwiftSyntax

/// Remove explicit `Sendable` conformance from non-public structs and enums.
///
/// In Swift 6, the compiler automatically infers `Sendable` for structs and enums whose
/// stored properties/associated values are all `Sendable`, as long as the type is not `public`.
/// Explicitly declaring `: Sendable` on these types is redundant.
///
/// This rule only flags non-public structs and enums. Classes, actors, and public types
/// are not checked because their `Sendable` conformance is either not inferred or must
/// be explicit for ABI stability.
///
/// Lint: If a redundant `Sendable` conformance is found, a lint warning is raised.
@_spi(Rules)
public final class RedundantSendable: SyntaxLintRule {

  public override class var isOptIn: Bool { true }

  public override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    checkSendable(modifiers: node.modifiers, inheritanceClause: node.inheritanceClause)
    return .visitChildren
  }

  public override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    checkSendable(modifiers: node.modifiers, inheritanceClause: node.inheritanceClause)
    return .visitChildren
  }

  private func checkSendable(
    modifiers: DeclModifierListSyntax,
    inheritanceClause: InheritanceClauseSyntax?
  ) {
    // Only non-public types get automatic Sendable inference.
    if let accessModifier = modifiers.accessLevelModifier,
      case .keyword(let keyword) = accessModifier.name.tokenKind,
      keyword == .public || keyword == .package
    {
      return
    }

    guard let inheritanceClause else { return }

    for inherited in inheritanceClause.inheritedTypes {
      if inherited.type.trimmedDescription == "Sendable" {
        diagnose(.removeRedundantSendable, on: inherited)
        return
      }
    }
  }
}

extension Finding.Message {
  fileprivate static let removeRedundantSendable: Finding.Message =
    "remove explicit 'Sendable'; it is inferred for non-public structs and enums"
}
