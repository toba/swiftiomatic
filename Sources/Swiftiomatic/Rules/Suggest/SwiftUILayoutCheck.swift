import SwiftSyntax

/// §8: Detects SwiftUI layout composition anti-patterns by tracking view nesting.
final class SwiftUILayoutCheck: BaseCheck {
    /// Stack tracking the current nesting of SwiftUI containers.
    private var containerStack: [String] = []

    // MARK: - Visit

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let callee = node.calledExpression.trimmedDescription

        guard SwiftUIContainerHelpers.trackedContainers.contains(callee) else {
            return .visitChildren
        }

        // Check for conflicts with ancestor containers before pushing.
        if let issue = SwiftUIContainerHelpers.checkNestedNavigationStack(
            callee: callee, containerStack: containerStack
        ) {
            emitIssue(issue, at: node)
        }
        if let issue = SwiftUIContainerHelpers.checkListInsideScrollView(
            callee: callee, containerStack: containerStack
        ) {
            emitIssue(issue, at: node)
        }
        if let issue = SwiftUIContainerHelpers.checkGeometryReaderInsideScrollView(
            callee: callee, containerStack: containerStack
        ) {
            emitIssue(issue, at: node)
        }

        containerStack.append(callee)

        // After pushing, check for multiple unbounded containers in a stack.
        if let issue = SwiftUIContainerHelpers.checkMultipleUnboundedContainers(
            containerStack: containerStack
        ) {
            emitIssue(issue, at: node)
        }

        return .visitChildren
    }

    override func visitPost(_ node: FunctionCallExprSyntax) {
        let callee = node.calledExpression.trimmedDescription

        guard SwiftUIContainerHelpers.trackedContainers.contains(callee) else {
            return
        }

        if let index = containerStack.lastIndex(of: callee) {
            containerStack.remove(at: index)
        }
    }

    // MARK: - Helpers

    private func emitIssue(_ issue: SwiftUIContainerHelpers.LayoutIssue, at node: FunctionCallExprSyntax) {
        addFinding(
            at: node,
            category: .agentReview,
            severity: issue.isHighSeverity ? .high : .medium,
            message: issue.reason,
            suggestion: issue.suggestion,
            confidence: issue.isHighSeverity ? .high : .medium
        )
    }
}
