import SwiftSyntax

/// Flag `nonisolated(unsafe)` on a `let` whose literal value is already `Sendable` .
///
/// `nonisolated(unsafe)` tells the compiler to stop checking a declaration. On a `let` bound to a
/// literal of a standard library type there is nothing to check, because the value is immutable and
/// `Sendable` . The marker then buys nothing and it silences the next real violation on that
/// declaration.
///
/// The rule reports only a literal initializer: a number, a boolean, a string with no
/// interpolation, or an array or dictionary of those. A type annotation must name a standard
/// library `Sendable` type, such as `Int` , `String` , `[Double]` or `[String: Int]?` . The rule
/// skips every other `let` , because the marker can be necessary there:
///
/// - A `Regex` is not `Sendable` . A regex literal, `try Regex(...)` and `NSRegularExpression` keep
///   the marker.
/// - A call, such as `DateFormatter()` , can build a class instance that is not `Sendable` .
/// - A literal can build a type that is not `Sendable` , such as `let items: NSMutableArray = []` .
///
/// Before you remove the marker, make sure that no other code depends on it. A module that does not
/// use strict concurrency checking can need a different fix.
///
/// Lint: A `nonisolated(unsafe) let` whose every binding takes a literal of a known `Sendable` type
/// raises a warning.
final class FlagUnnecessaryNonisolatedUnsafe: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .unsafety }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard node.bindingSpecifier.tokenKind == .keyword(.let),
              let modifier = unsafeModifier(node.modifiers),
              !node.bindings.isEmpty else { return .visitChildren }

        for binding in node.bindings {
            guard let value = binding.initializer?.value,
                  isLiteral(value),
                  binding.typeAnnotation.map({ isKnownSendable($0.type) }) ?? true
            else { return .visitChildren }
        }
        diagnose(.unnecessaryNonisolatedUnsafe, on: modifier)
        return .visitChildren
    }

    private func unsafeModifier(_ modifiers: DeclModifierListSyntax) -> DeclModifierSyntax? {
        modifiers.first { $0.name.text == "nonisolated" && $0.detail?.detail.text == "unsafe" }
    }

    /// Standard library types that are `Sendable` and that a literal can build.
    private static let sendableTypeNames: Set<String> = [
        "Int", "Int8", "Int16", "Int32", "Int64", "Int128",
        "UInt", "UInt8", "UInt16", "UInt32", "UInt64", "UInt128",
        "Double", "Float", "Float16", "Bool", "String", "Character", "Unicode.Scalar",
        "StaticString",
    ]

    /// Standard library generic types that are `Sendable` when their arguments are `Sendable` .
    private static let sendableGenericNames: Set<String> = [
        "Array", "Dictionary", "Set", "Optional", "ContiguousArray",
    ]

    /// Whether the rule can prove that `type` is `Sendable` .
    private func isKnownSendable(_ type: TypeSyntax) -> Bool {
        if let array = type.as(ArrayTypeSyntax.self) { return isKnownSendable(array.element) }

        if let dictionary = type.as(DictionaryTypeSyntax.self) {
            return isKnownSendable(dictionary.key) && isKnownSendable(dictionary.value)
        }

        if let optional = type.as(OptionalTypeSyntax.self) {
            return isKnownSendable(optional.wrappedType)
        }

        if let identifier = type.as(IdentifierTypeSyntax.self) {
            guard let arguments = identifier.genericArgumentClause?.arguments else {
                return Self.sendableTypeNames.contains(identifier.name.text)
            }
            return Self.sendableGenericNames.contains(identifier.name.text)
                && arguments.allSatisfy {
                    guard case let .type(argument) = $0.argument else { return false }
                    return isKnownSendable(argument)
                }
        }
        return Self.sendableTypeNames.contains(type.trimmedDescription)
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
