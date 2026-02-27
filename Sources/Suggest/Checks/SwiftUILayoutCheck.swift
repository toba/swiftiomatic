import SwiftSyntax

/// §8: Detects SwiftUI layout composition anti-patterns by tracking view nesting.
public final class SwiftUILayoutCheck: BaseCheck {

    /// Container names we track for nesting analysis.
    private static let trackedContainers: Set<String> = [
        "NavigationStack", "List", "ScrollView", "GeometryReader",
        "VStack", "HStack", "ZStack", "Form",
    ]

    /// Containers that provide their own scrolling.
    private static let unboundedContainers: Set<String> = [
        "List", "ScrollView", "Form",
    ]

    /// Stack containers that can hold multiple children.
    private static let stackContainers: Set<String> = [
        "VStack", "HStack", "ZStack",
    ]

    /// Stack tracking the current nesting of SwiftUI containers.
    private var containerStack: [String] = []

    // MARK: - Visit

    override public func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let callee = node.calledExpression.trimmedDescription

        guard Self.trackedContainers.contains(callee) else {
            return .visitChildren
        }

        // Check for conflicts with ancestor containers before pushing.
        checkNestedNavigationStack(callee: callee, node: node)
        checkListInsideScrollView(callee: callee, node: node)
        checkGeometryReaderInsideScrollView(callee: callee, node: node)

        containerStack.append(callee)

        // After pushing, check for multiple unbounded containers in a stack.
        checkMultipleUnboundedContainers(node: node)

        return .visitChildren
    }

    override public func visitPost(_ node: FunctionCallExprSyntax) {
        let callee = node.calledExpression.trimmedDescription

        guard Self.trackedContainers.contains(callee) else {
            return
        }

        // Pop the most recent matching entry. Walk from the end to handle
        // edge cases where the same container type is nested.
        if let index = containerStack.lastIndex(of: callee) {
            containerStack.remove(at: index)
        }
    }

    // MARK: - Checks

    /// NavigationStack inside another NavigationStack causes double navigation bars.
    private func checkNestedNavigationStack(callee: String, node: FunctionCallExprSyntax) {
        guard callee == "NavigationStack",
              containerStack.contains("NavigationStack")
        else { return }

        addFinding(
            at: node,
            category: .agentReview,
            severity: .high,
            message: "Nested NavigationStack — causes double navigation bars and broken navigation",
            suggestion: "Remove the inner NavigationStack; only the root view should own one",
            confidence: .high
        )
    }

    /// List already scrolls; wrapping it in ScrollView causes layout conflicts.
    private func checkListInsideScrollView(callee: String, node: FunctionCallExprSyntax) {
        guard callee == "List",
              containerStack.contains("ScrollView")
        else { return }

        addFinding(
            at: node,
            category: .agentReview,
            severity: .high,
            message: "List inside ScrollView — List has built-in scrolling, nesting causes conflicts",
            suggestion: "Remove the outer ScrollView or replace List with ForEach",
            confidence: .high
        )
    }

    /// GeometryReader inside ScrollView receives an undefined proposed size.
    private func checkGeometryReaderInsideScrollView(callee: String, node: FunctionCallExprSyntax) {
        guard callee == "GeometryReader",
              containerStack.contains("ScrollView")
        else { return }

        addFinding(
            at: node,
            category: .agentReview,
            severity: .high,
            message: "GeometryReader inside ScrollView — proposed size is undefined in the scroll axis",
            suggestion: "Move GeometryReader outside the ScrollView or use a fixed frame",
            confidence: .high
        )
    }

    /// Two or more unbounded containers (List, ScrollView, Form) inside a single
    /// stack container compete for space, causing layout issues.
    private func checkMultipleUnboundedContainers(node: FunctionCallExprSyntax) {
        // Only check when the current container is unbounded.
        guard let current = containerStack.last,
              Self.unboundedContainers.contains(current)
        else { return }

        // Find the nearest parent stack container in the stack.
        guard let stackIndex = containerStack.dropLast().lastIndex(where: {
            Self.stackContainers.contains($0)
        }) else { return }

        // Count unbounded containers that are direct children of that stack
        // (i.e., appear after the stack in the container stack with no
        // intervening stack container).
        let childrenAfterStack = containerStack[(stackIndex + 1)...]
        let hasInterveningStack = childrenAfterStack.dropLast().contains(where: {
            Self.stackContainers.contains($0)
        })
        guard !hasInterveningStack else { return }

        let unboundedCount = childrenAfterStack.filter {
            Self.unboundedContainers.contains($0)
        }.count

        guard unboundedCount >= 2 else { return }

        let stackName = containerStack[stackIndex]
        addFinding(
            at: node,
            category: .agentReview,
            severity: .medium,
            message: "Multiple unbounded containers (\(unboundedCount)) inside \(stackName) — they compete for space",
            suggestion: "Give explicit frames to each container or restructure the layout",
            confidence: .medium
        )
    }
}
