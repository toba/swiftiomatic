import SwiftSyntax

/// A `Bool` name should read as an assertion about the receiver.
///
/// The API Design Guidelines say a non-mutating boolean reads as an assertion at the use site, so
/// `if session.isActive` reads and `if session.active` does not. The conventional openers are `is`
/// , `has` , `can` , `should` and `will` .
///
/// The rule checks a property with a `Bool` annotation and a method that takes no argument and
/// returns `Bool` . It skips an `override` , because the name belongs to the superclass. It cannot
/// see an inferred type, so a property with no annotation raises nothing.
///
/// Ships off by default. The prefix list is a convention, not a compiler rule, and a codebase with
/// its own vocabulary reports a long list of names it does not intend to change.
///
/// Lint: A `Bool` property or a `Bool`-returning method with no argument, whose name starts with
/// none of the five prefixes, raises a warning.
final class RequireBooleanAssertionNames: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .naming }
    override class var defaultValue: LintOnlyValue { .init(lint: .no) }

    private static let prefixes = ["is", "has", "can", "should", "will"]

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard !isOverride(node.modifiers) else { return .visitChildren }

        for binding in node.bindings {
            guard let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier,
                  let annotation = binding.typeAnnotation,
                  isBool(annotation.type) else { continue }
            check(name)
        }
        return .visitChildren
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        guard !isOverride(node.modifiers),
              node.signature.parameterClause.parameters.isEmpty,
              let returned = node.signature.returnClause?.type,
              isBool(returned) else { return .visitChildren }

        check(node.name)
        return .visitChildren
    }

    private func isOverride(_ modifiers: DeclModifierListSyntax) -> Bool {
        modifiers.contains { $0.name.text == "override" }
    }

    private func isBool(_ type: TypeSyntax) -> Bool {
        let text = type.trimmedDescription
        return text == "Bool" || text == "Bool?"
    }

    private func check(_ token: TokenSyntax) {
        let name = token.text
        guard !hasAssertionPrefix(name) else { return }
        diagnose(.requireAssertionName(name), on: token)
    }

    /// Whether the name opens with one of the prefixes as a whole word, so `island` does not pass
    /// on the strength of its first two letters.
    private func hasAssertionPrefix(_ name: String) -> Bool {
        for prefix in Self.prefixes where name.hasPrefix(prefix) {
            let rest = name.dropFirst(prefix.count)
            if rest.isEmpty { return true }
            if let next = rest.first, next.isUppercase { return true }
        }
        return false
    }
}

fileprivate extension Finding.Message {
    static func requireAssertionName(_ name: String) -> Finding.Message {
        """
        '\(name)' is 'Bool' — start the name with 'is', 'has', 'can', 'should' or 'will' so it \
        reads as an assertion
        """
    }
}
