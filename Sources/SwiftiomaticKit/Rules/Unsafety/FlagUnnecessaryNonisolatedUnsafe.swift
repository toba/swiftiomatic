import SwiftSyntax

/// Flag `nonisolated(unsafe)` on a `let` the compiler already accepts.
///
/// `nonisolated(unsafe)` tells the compiler to stop checking a declaration. On a `let` bound to a
/// literal there is nothing to check, because the value is immutable and already `Sendable` . The
/// marker then buys nothing and it silences the next real violation on that declaration.
///
/// The rule reports only a literal initializer: a number, a boolean, a string with no
/// interpolation, or an array or dictionary of those. A `let` bound to a call keeps the marker,
/// because the rule cannot see whether the constructed type is `Sendable` .
///
/// Lint: A `nonisolated(unsafe) let` whose every binding takes a literal raises a warning.
final class FlagUnnecessaryNonisolatedUnsafe: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .unsafety }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard node.bindingSpecifier.tokenKind == .keyword(.let),
              let modifier = unsafeModifier(node.modifiers),
              !node.bindings.isEmpty else { return .visitChildren }

        for binding in node.bindings {
            guard let value = binding.initializer?.value, isLiteral(value)
            else { return .visitChildren }
        }
        diagnose(.unnecessaryNonisolatedUnsafe, on: modifier)
        return .visitChildren
    }

    private func unsafeModifier(_ modifiers: DeclModifierListSyntax) -> DeclModifierSyntax? {
        modifiers.first { $0.name.text == "nonisolated" && $0.detail?.detail.text == "unsafe" }
    }

    private func isLiteral(_ expr: ExprSyntax) -> Bool {
        if expr.is(IntegerLiteralExprSyntax.self) { return true }
        if expr.is(FloatLiteralExprSyntax.self) { return true }
        if expr.is(BooleanLiteralExprSyntax.self) { return true }

        if let string = expr.as(StringLiteralExprSyntax.self) {
            return string.segments.allSatisfy { $0.is(StringSegmentSyntax.self) }
        }
        if let prefixed = expr.as(PrefixOperatorExprSyntax.self) {
            return prefixed.operator.text == "-" && isLiteral(prefixed.expression)
        }
        if let array = expr.as(ArrayExprSyntax.self) {
            return array.elements.allSatisfy { isLiteral($0.expression) }
        }

        if let dictionary = expr.as(DictionaryExprSyntax.self) {
            guard case let .elements(elements) = dictionary.content else { return true }
            return elements.allSatisfy { isLiteral($0.key) && isLiteral($0.value) }
        }
        return false
    }
}

fileprivate extension Finding.Message {
    static let unnecessaryNonisolatedUnsafe: Finding.Message = """
        'nonisolated(unsafe)' is not needed on a 'let' initialized with a literal — the value is \
        already 'Sendable'
        """
}
