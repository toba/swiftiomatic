import SwiftSyntax

/// Flag a function, initializer or subscript that takes three or more `Bool` parameters.
///
/// Several `Bool` flags make a signature long, and each new flag changes it again. A call site such
/// as `make(x, breakBefore: true, breakAfter: false, indivisible: true)` also reads poorly. An
/// `OptionSet` parameter groups the flags into one value that a caller writes as
/// `[.breakBefore, .indivisible]`, and a new flag does not change the signature.
///
/// Only a parameter of the plain type `Bool` counts. An `override` is exempt, because the
/// overridden declaration fixes the signature.
///
/// Lint: A declaration with three or more `Bool` parameters raises a warning.
final class UseOptionSetForBoolFlags: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .declarations }
    override class var guidance: GuidanceLevel { .consider }

    /// The smallest number of `Bool` parameters that the rule reports.
    private static let minimumFlags = 3

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        check(node.signature.parameterClause, modifiers: node.modifiers, name: node.name)
        return .visitChildren
    }

    override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        check(node.signature.parameterClause, modifiers: node.modifiers, name: node.initKeyword)
        return .visitChildren
    }

    override func visit(_ node: SubscriptDeclSyntax) -> SyntaxVisitorContinueKind {
        check(node.parameterClause, modifiers: node.modifiers, name: node.subscriptKeyword)
        return .visitChildren
    }

    private func check(
        _ parameters: FunctionParameterClauseSyntax,
        modifiers: DeclModifierListSyntax,
        name: TokenSyntax
    ) {
        guard !modifiers.contains(anyOf: [.override]) else { return }
        let count = parameters.parameters.count { $0.type.isPlainBool }
        guard count >= Self.minimumFlags else { return }
        diagnose(.useOptionSetForBoolFlags(name.text, count), on: name)
    }
}

fileprivate extension TypeSyntax {
    /// Whether the type is `Bool` or `Swift.Bool`.
    var isPlainBool: Bool {
        if let identifier = self.as(IdentifierTypeSyntax.self) {
            return identifier.name.text == "Bool" && identifier.genericArgumentClause == nil
        }
        guard let member = self.as(MemberTypeSyntax.self) else { return false }
        return member.name.text == "Bool" && member.baseType.trimmedDescriptionEquals("Swift")
    }
}

fileprivate extension Finding.Message {
    static func useOptionSetForBoolFlags(_ name: String, _ count: Int) -> Finding.Message {
        "'\(name)' takes \(count) 'Bool' parameters; combine the flags into one 'OptionSet' parameter"
    }
}
