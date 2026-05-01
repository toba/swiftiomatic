import SwiftSyntax

/// Lint inline `.sorted` / `.filter` / `.map` / `.compactMap` / `.reversed` chains in the data
/// argument of `ForEach` . The expression is recomputed on every render — hoist into a `@State` /
/// `@Observable` value or a computed property.
final class NoSortFilterInForEachData: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }

    private static let recomputingMethods: Set<String> = [
        "sorted",
        "filter",
        "map",
        "compactMap",
        "flatMap",
        "reversed",
        "shuffled",
    ]

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let ident = node.calledExpression.as(DeclReferenceExprSyntax.self),
              ident.baseName.text == "ForEach",
              let firstArg = node.arguments.first else { return .visitChildren }

        if let dataCall = firstArg.expression.as(FunctionCallExprSyntax.self),
           let member = dataCall.calledExpression.as(MemberAccessExprSyntax.self),
           Self.recomputingMethods.contains(member.declName.baseName.text)
        {
            diagnose(.recomputingForEachData(member.declName.baseName.text), on: dataCall)
        }
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static func recomputingForEachData(_ method: String) -> Finding.Message {
        "'.\(method)' in 'ForEach' data is recomputed on every render — hoist into a stored or computed property"
    }
}
