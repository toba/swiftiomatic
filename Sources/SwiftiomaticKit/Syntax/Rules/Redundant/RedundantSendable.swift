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
///
/// Format: The redundant `Sendable` conformance is removed from the inheritance clause.
final class RedundantSendable: SyntaxFormatRule {
  static let group: ConfigGroup? = .redundancies

  static let defaultHandling: RuleHandling = .off

  override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
    let visited = super.visit(node).cast(StructDeclSyntax.self)
    guard !isPublicOrPackage(visited.modifiers),
      let inheritanceClause = visited.inheritanceClause,
      let inherited = inheritanceClause.inherited(named: "Sendable")
    else {
      return DeclSyntax(visited)
    }
    diagnose(.removeRedundantSendable, on: inherited)
    var result = visited
    let newClause = inheritanceClause.removing(named: "Sendable")
    result.inheritanceClause = newClause
    if newClause == nil {
      // The entire clause was removed — ensure the member block brace has leading space.
      result.memberBlock.leftBrace.leadingTrivia = .space
    }
    return DeclSyntax(result)
  }

  override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
    let visited = super.visit(node).cast(EnumDeclSyntax.self)
    guard !isPublicOrPackage(visited.modifiers),
      let inheritanceClause = visited.inheritanceClause,
      let inherited = inheritanceClause.inherited(named: "Sendable")
    else {
      return DeclSyntax(visited)
    }
    diagnose(.removeRedundantSendable, on: inherited)
    var result = visited
    let newClause = inheritanceClause.removing(named: "Sendable")
    result.inheritanceClause = newClause
    if newClause == nil {
      result.memberBlock.leftBrace.leadingTrivia = .space
    }
    return DeclSyntax(result)
  }

  private func isPublicOrPackage(_ modifiers: DeclModifierListSyntax) -> Bool {
    guard let accessModifier = modifiers.accessLevelModifier,
      case .keyword(let keyword) = accessModifier.name.tokenKind
    else { return false }
    return keyword == .public || keyword == .package
  }
}

extension Finding.Message {
  fileprivate static let removeRedundantSendable: Finding.Message =
    "remove explicit 'Sendable'; it is inferred for non-public structs and enums"
}
