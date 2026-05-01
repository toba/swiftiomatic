import SwiftSyntax

/// Remove backticks around `self` in optional unwrap expressions.
///
/// Since Swift 4.2, `guard let self = self` is valid without backticks. Writing
/// `` guard let `self` = self `` is a holdover from older Swift versions.
///
/// Lint: If a backticked `self` is found in an optional binding, a finding is raised.
///
/// Rewrite: The backticks are removed.
final class NoBacktickedSelf: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .redundancies }

    static func transform(
        _ node: OptionalBindingConditionSyntax,
        parent _: Syntax?,
        context: Context
    ) -> OptionalBindingConditionSyntax {
        // Match: let `self` = self
        guard let identifierPattern = node.pattern.as(IdentifierPatternSyntax.self),
              case let .identifier(text) = identifierPattern.identifier.tokenKind,
              text == "`self`",
              let initializer = node.initializer,
              let declRef = initializer.value.as(DeclReferenceExprSyntax.self),
              declRef.baseName.tokenKind == .keyword(.self) else { return node }

        Self.diagnose(
            .removeBackticksAroundSelf, on: identifierPattern.identifier, context: context)

        var result = node
        let newIdentifier = identifierPattern.identifier.with(\.tokenKind, .identifier("self"))
        result.pattern = PatternSyntax(identifierPattern.with(\.identifier, newIdentifier))
        return result
    }
}

fileprivate extension Finding.Message {
    static let removeBackticksAroundSelf: Finding.Message =
        "remove backticks around 'self' in optional binding"
}
