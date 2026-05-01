import SwiftSyntax

/// Lint chains of 3+ collection transforms ( `.map` , `.filter` , `.compactMap` , `.flatMap` ,
/// `.prefix` , `.dropFirst` ). Each step allocates an intermediate `Array` . Inserting `.lazy` at
/// the head of the chain forwards lazily and avoids the allocations.
final class UseLazyForLongChainOps: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }

    private static let chainableMethods: Set<String> = [
        "map",
        "filter",
        "compactMap",
        "flatMap",
        "prefix",
        "dropFirst",
        "dropLast",
    ]

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        // Only emit on the outermost chain link to avoid duplicate findings.
        if isChainLink(node.parent) { return .visitChildren }
        let length = chainLength(of: node)
        if length >= 3 { diagnose(.useLazyForLongChainOps(length), on: node) }
        return .visitChildren
    }

    private func isChainLink(_ syntax: Syntax?) -> Bool {
        guard let syntax,
              let member = syntax.as(MemberAccessExprSyntax.self),
              let parentCall = member.parent?.as(FunctionCallExprSyntax.self),
              parentCall.calledExpression.id == member.id,
              Self.chainableMethods.contains(member.declName.baseName.text) else { return false }
        return true
    }

    /// Walks down the receiver chain counting consecutive chainable calls.
    private func chainLength(of call: FunctionCallExprSyntax) -> Int {
        var current = ExprSyntax(call)
        var length = 0

        while let funcCall = current.as(FunctionCallExprSyntax.self),
              let member = funcCall.calledExpression.as(MemberAccessExprSyntax.self),
              Self.chainableMethods.contains(member.declName.baseName.text),
              let receiver = member.base
        {
            length += 1
            current = receiver
        }
        return length
    }
}

fileprivate extension Finding.Message {
    static func useLazyForLongChainOps(_ count: Int) -> Finding.Message {
        "chain of \(count) collection transforms allocates intermediate arrays — consider '.lazy'"
    }
}
