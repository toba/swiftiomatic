import SwiftSyntax

/// Finds mutations on a named collection inside a for-in body. Used by both
/// `PerformanceAntiPatternsCheck` (suggest) and `PerformanceAntiPatternsRule` (lint).
final class MutationDuringIterationFinder: SyntaxVisitor {
    private let mutatingPrefixes: [String]
    var foundMutation = false

    init(collectionName: String, viewMode: SyntaxTreeViewMode) {
        mutatingPrefixes = [
            "\(collectionName).remove",
            "\(collectionName).insert",
            "\(collectionName).append",
            "\(collectionName).removeAll",
        ]
        super.init(viewMode: viewMode)
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let callee = node.calledExpression.trimmedDescription
        if mutatingPrefixes.contains(where: { callee.hasPrefix($0) }) {
            foundMutation = true
        }
        return .visitChildren
    }
}
