import SwiftSyntax

/// Flag `@unchecked Sendable` conformances. The `@unchecked` opts out of compiler-enforced
/// data-race safety — the type might still be safe (e.g. all storage is protected by a lock),
/// but the conformance bypasses verification and warrants human review. SE-0470's `sending`,
/// metatype-aware `Sendable`, or refactoring to actor isolation often eliminates the need.
///
/// Flag-only — choosing the correct fix needs type information this rule doesn't have.
final class FlagUncheckedSendable: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .unsafety }

    override func visit(_ node: InheritedTypeSyntax) -> SyntaxVisitorContinueKind {
        guard let attributed = node.type.as(AttributedTypeSyntax.self) else { return .visitChildren }

        let hasUnchecked = attributed.attributes.contains { element in
            guard case let .attribute(attr) = element,
                  let ident = attr.attributeName.as(IdentifierTypeSyntax.self) else { return false }
            return ident.name.text == "unchecked"
        }
        guard hasUnchecked else { return .visitChildren }

        let baseName = attributed.baseType.trimmedDescription
        if baseName == "Sendable" || baseName.hasSuffix(".Sendable") {
            diagnose(.uncheckedSendable, on: node.type)
        }
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static let uncheckedSendable: Finding.Message =
        "'@unchecked Sendable' bypasses data-race verification — review whether actor isolation, 'Mutex', or 'sending' would let the compiler check it"
}
