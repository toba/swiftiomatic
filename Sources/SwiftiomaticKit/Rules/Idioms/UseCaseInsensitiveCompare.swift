import SwiftSyntax

/// Compare or search strings case-insensitively with Foundation's comparison options.
///
/// A check that converts both sides with the same `lowercased()` or `uppercased()` call only
/// ignores case. Each conversion allocates a new string, and the conversion does not fold
/// diacritics, so `"Café"` and `"cafe"` still differ. Foundation's comparison options state the
/// intent in one call:
///
/// - For equality, use `a.caseInsensitiveCompare(b) == .orderedSame` . When accents must also
///   match, use `a.compare(b, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame`
///   .
/// - For `contains`, use `title.localizedStandardContains(query)` . It ignores case and diacritics
///   and follows the current locale, as system search does.
/// - For `hasPrefix`, use `title.range(of: query, options: [.caseInsensitive, .anchored]) != nil` .
/// - For `hasSuffix`, add `.backwards` to the options to anchor the match at the end.
///
/// Add `.diacriticInsensitive` to the options when the match must also ignore accents.
///
/// Keep the conversion when the code stores or reuses the converted string, for example as a
/// dictionary key.
///
/// The rule looks only at inline conversions. A conversion that the code stores in a variable is
/// not part of the pattern, because the code can reuse the stored string. The rule stays silent in
/// a file that declares its own `lowercased()` or `uppercased()` function, because the receiver can
/// be a type other than `String`.
///
/// Lint: An equality check, or a `contains`, `hasPrefix` or `hasSuffix` call, whose two sides both
/// apply the same case conversion raises a warning.
final class UseCaseInsensitiveCompare: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }
    override class var guidance: GuidanceLevel { .consider }

    private static let conversions: Set<String> = ["lowercased", "uppercased"]
    private static let searchMethods: Set<String> = ["contains", "hasPrefix", "hasSuffix"]

    /// The file declares its own case conversion function.
    private var fileDeclaresConversion = false

    override func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
        fileDeclaresConversion = node.tokens(viewMode: .sourceAccurate).contains { token in
            guard Self.conversions.contains(token.text),
                token.previousToken(viewMode: .sourceAccurate)?.tokenKind == .keyword(.func)
            else { return false }
            return true
        }
        return .visitChildren
    }

    override func visit(_ node: InfixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        guard !fileDeclaresConversion,
              let op = node.operator.as(BinaryOperatorExprSyntax.self),
              op.operator.text == "==" || op.operator.text == "!=",
              let left = Self.conversionName(node.leftOperand),
              let right = Self.conversionName(node.rightOperand),
              left == right else { return .visitChildren }
        diagnose(.compareInsensitively(conversion: left), on: node.leftOperand)
        return .visitChildren
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard !fileDeclaresConversion,
              let member = node.calledExpression.as(MemberAccessExprSyntax.self),
              Self.searchMethods.contains(member.declName.baseName.text),
              let base = member.base,
              let receiver = Self.conversionName(base),
              let argument = node.arguments.firstAndOnly,
              argument.label == nil,
              let other = Self.conversionName(argument.expression),
              receiver == other else { return .visitChildren }
        diagnose(
            .searchInsensitively(conversion: receiver, method: member.declName.baseName.text),
            on: node
        )
        return .visitChildren
    }

    /// The name of the case conversion when `expr` is a call such as `x.lowercased()` or
    /// `x?.lowercased()` with no arguments.
    private static func conversionName(_ expr: ExprSyntax) -> String? {
        guard let call = expr.as(FunctionCallExprSyntax.self),
              call.arguments.isEmpty,
              call.trailingClosure == nil,
              let member = call.calledExpression.as(MemberAccessExprSyntax.self),
              member.base != nil else { return nil }
        let name = member.declName.baseName.text
        return conversions.contains(name) ? name : nil
    }
}

fileprivate extension Finding.Message {
    static func compareInsensitively(conversion: String) -> Finding.Message {
        "compare these strings with 'caseInsensitiveCompare(_:)' or 'compare(_:options:)' instead of converting both sides with '\(conversion)()'"
    }

    static func searchInsensitively(conversion: String, method: String) -> Finding.Message {
        let replacement =
            switch method {
                case "hasPrefix": "'range(of:options: [.caseInsensitive, .anchored])'"
                case "hasSuffix": "'range(of:options: [.caseInsensitive, .anchored, .backwards])'"
                default: "'localizedStandardContains(_:)' or 'range(of:options:)'"
            }
        return "search with \(replacement) instead of converting both sides with '\(conversion)()' before '\(method)'"
    }
}
