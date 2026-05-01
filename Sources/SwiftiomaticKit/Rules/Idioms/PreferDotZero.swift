import SwiftSyntax

/// Prefer `.zero` over explicit zero-valued initializers.
///
/// `CGPoint(x: 0, y: 0)` , `CGSize(width: 0, height: 0)` ,
/// `CGRect(x: 0, y: 0, width: 0, height: 0)` and similar are equivalent to the platform-provided
/// `.zero` constant. The shorthand reads better and avoids subtle inconsistencies (e.g. `0.0` vs
/// `0` literal kinds).
///
/// Recognised types: `CGPoint` , `CGSize` , `CGRect` , `CGVector` , `UIEdgeInsets` , `NSEdgeInsets`
/// , `NSPoint` , `NSSize` , `NSRect` .
///
/// Lint: A warning is raised on a fully-zero initializer.
///
/// Rewrite: The call is replaced with `<Type>.zero` .
final class PreferDotZero: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }
    override class var defaultValue: BasicRuleValue { .init(rewrite: true, lint: .warn) }

    /// Maps type name → expected argument labels for the all-zero match.
    private static let zeroSignatures: [String: [String]] = [
        "CGPoint": ["x", "y"],
        "CGSize": ["width", "height"],
        "CGRect": ["x", "y", "width", "height"],
        "CGVector": ["dx", "dy"],
        "UIEdgeInsets": ["top", "left", "bottom", "right"],
        "NSEdgeInsets": ["top", "left", "bottom", "right"],
        "NSPoint": ["x", "y"],
        "NSSize": ["width", "height"],
        "NSRect": ["x", "y", "width", "height"],
    ]

    static func transform(
        _ call: FunctionCallExprSyntax,
        parent _: Syntax?,
        context: Context
    ) -> ExprSyntax {
        guard let typeName = matchedTypeName(call) else { return ExprSyntax(call) }

        Self.diagnose(.preferDotZero(type: typeName), on: call, context: context)

        let zeroAccess = MemberAccessExprSyntax(
            base: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(typeName))),
            period: .periodToken(),
            declName: DeclReferenceExprSyntax(baseName: .identifier("zero"))
        )

        var result = ExprSyntax(zeroAccess)
        result.leadingTrivia = call.leadingTrivia
        result.trailingTrivia = call.trailingTrivia
        return result
    }

    private static func matchedTypeName(_ call: FunctionCallExprSyntax) -> String? {
        guard let identifier = call.calledExpression.as(DeclReferenceExprSyntax.self) else {
            return nil
        }
        let name = identifier.baseName.text
        guard let expectedLabels = Self.zeroSignatures[name] else { return nil }

        let actualLabels = call.arguments.map { $0.label?.text }
        guard actualLabels.elementsEqual(expectedLabels, by: { $0 == $1 }) else { return nil }
        guard call.arguments.allSatisfy({ isZeroLiteral($0.expression) }) else { return nil }
        return name
    }

    private static func isZeroLiteral(_ expr: ExprSyntax) -> Bool {
        if let intLit = expr.as(IntegerLiteralExprSyntax.self) { return intLit.literal.text == "0" }

        if let floatLit = expr.as(FloatLiteralExprSyntax.self) {
            // Strip trailing zeros after the dot — anything like 0, 0.0, 0.000 is zero.
            let text = floatLit.literal.text
            // Quick scan: every character should be 0, '.', or '+'/'-'/'e'/'E'-prefixed scientific
            // notation that nets to zero.
            if let value = Double(text) { return value == 0 }
            return false
        }
        return false
    }
}

fileprivate extension Finding.Message {
    static func preferDotZero(type: String) -> Finding.Message {
        "prefer '\(type).zero' over an all-zero initializer"
    }
}
