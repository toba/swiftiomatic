import SwiftSyntax

/// Finds mutations on a named collection inside a for-in body. Used by both
/// `PerformanceAntiPatternsCheck` (suggest) and `PerformanceAntiPatternsRule` (lint).
final class MutationDuringIterationFinder: SyntaxVisitor {
    let collectionName: String
    var foundMutation = false

    init(collectionName: String, viewMode: SyntaxTreeViewMode) {
        self.collectionName = collectionName
        super.init(viewMode: viewMode)
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let callee = node.calledExpression.trimmedDescription
        let mutatingMethods = [
            "\(collectionName).remove",
            "\(collectionName).insert",
            "\(collectionName).append",
            "\(collectionName).removeAll",
        ]
        if mutatingMethods.contains(where: { callee.hasPrefix($0) }) {
            foundMutation = true
        }
        return .visitChildren
    }
}
