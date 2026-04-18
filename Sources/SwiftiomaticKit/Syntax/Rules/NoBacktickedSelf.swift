import SwiftSyntax

/// Remove backticks around `self` in optional unwrap expressions.
///
/// Since Swift 4.2, `guard let self = self` is valid without backticks.
/// Writing `` guard let `self` = self `` is a holdover from older Swift versions.
///
/// Lint: If a backticked `self` is found in an optional binding, a finding is raised.
///
/// Format: The backticks are removed.
final class NoBacktickedSelf: SyntaxFormatRule {

  override func visit(
    _ node: OptionalBindingConditionSyntax
  ) -> OptionalBindingConditionSyntax {
    // Match: let `self` = self
    guard let identifierPattern = node.pattern.as(IdentifierPatternSyntax.self),
      case .identifier(let text) = identifierPattern.identifier.tokenKind,
      text == "`self`",
      let initializer = node.initializer,
      let declRef = initializer.value.as(DeclReferenceExprSyntax.self),
      declRef.baseName.tokenKind == .keyword(.self)
    else {
      return node
    }

    diagnose(.removeBackticksAroundSelf, on: identifierPattern.identifier)

    var result = node
    let newIdentifier = identifierPattern.identifier.with(\.tokenKind, .identifier("self"))
    result.pattern = PatternSyntax(identifierPattern.with(\.identifier, newIdentifier))
    return result
  }
}

extension Finding.Message {
  fileprivate static let removeBackticksAroundSelf: Finding.Message =
    "remove backticks around 'self' in optional binding"
}
