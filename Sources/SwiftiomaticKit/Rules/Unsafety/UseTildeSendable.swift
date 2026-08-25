import SwiftSyntax

/// Flag the unavailable-conformance idiom for marking a type non-`Sendable` .
///
/// SE-0518 adds `~Sendable` , which says the same thing on the type itself. The two differ in one
/// way that matters: an unavailable conformance is inherited, so no subclass can ever declare
/// `@unchecked Sendable` . A `~Sendable` base leaves that door open for a subclass that protects
/// its own state.
///
/// Lint: An `extension` marked `@available(*, unavailable)` that conforms a type to `Sendable`
/// raises a warning.
final class UseTildeSendable: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .unsafety }

    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let inheritance = node.inheritanceClause,
              let sendable = inheritance.sendableConformance,
              node.attributes.hasUnconditionalUnavailable else { return .visitChildren }

        diagnose(.useTildeSendable, on: sendable)
        return .visitChildren
    }
}

fileprivate extension InheritanceClauseSyntax {
    /// The inherited type that names `Sendable` , with or without an `@unchecked` attribute.
    var sendableConformance: InheritedTypeSyntax? {
        inheritedTypes.first { inherited in
            let name = inherited.type.trimmedDescription
            return name == "Sendable" || name.hasSuffix(" Sendable")
        }
    }
}

fileprivate extension AttributeListSyntax {
    /// Whether the list holds an `@available(*, unavailable)` that applies to every platform.
    ///
    /// A platform-scoped `@available(macOS, unavailable)` is excluded. That one is a real platform
    /// gate, and `~Sendable` cannot express it.
    var hasUnconditionalUnavailable: Bool {
        for element in self {
            guard case let .attribute(attribute) = element,
                  let name = attribute.attributeName.as(IdentifierTypeSyntax.self),
                  name.name.text == "available",
                  case let .availability(arguments)? = attribute.arguments else { continue }

            var hasWildcard = false
            var hasUnavailable = false

            for argument in arguments {
                switch argument.argument {
                    case let .token(token) where token.tokenKind == .binaryOperator("*"):
                        hasWildcard = true
                    case let .token(token) where token.text == "unavailable": hasUnavailable = true
                    default: break
                }
            }

            if hasWildcard, hasUnavailable { return true }
        }
        return false
    }
}

fileprivate extension Finding.Message {
    static let useTildeSendable: Finding.Message =
        "an unavailable 'Sendable' conformance is inherited, so no subclass can opt in — declare the type ': ~Sendable' instead (SE-0518)"
}
