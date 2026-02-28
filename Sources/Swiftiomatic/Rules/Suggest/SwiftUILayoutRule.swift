import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct SwiftUILayoutRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "swiftui_layout",
        name: "SwiftUI Layout",
        description: "Detects SwiftUI layout composition anti-patterns like nested NavigationStack or List inside ScrollView",
        kind: .lint,
        nonTriggeringExamples: [
            Example("NavigationStack { List { Text(\"Hello\") } }"),
        ],
        triggeringExamples: [
            Example("NavigationStack { ↓NavigationStack { Text(\"Hello\") } }"),
        ]
    )
}

private extension SwiftUILayoutRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private static let trackedContainers: Set<String> = [
            "NavigationStack", "List", "ScrollView", "GeometryReader",
            "VStack", "HStack", "ZStack", "Form",
        ]
        private static let unboundedContainers: Set<String> = ["List", "ScrollView", "Form"]
        private static let stackContainers: Set<String> = ["VStack", "HStack", "ZStack"]

        private var containerStack: [String] = []

        override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
            let callee = node.calledExpression.trimmedDescription
            guard Self.trackedContainers.contains(callee) else { return .visitChildren }

            checkNestedNavigationStack(callee: callee, node: node)
            checkListInsideScrollView(callee: callee, node: node)
            checkGeometryReaderInsideScrollView(callee: callee, node: node)

            containerStack.append(callee)
            checkMultipleUnboundedContainers(node: node)

            return .visitChildren
        }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            let callee = node.calledExpression.trimmedDescription
            guard Self.trackedContainers.contains(callee) else { return }
            if let index = containerStack.lastIndex(of: callee) {
                containerStack.remove(at: index)
            }
        }

        private func checkNestedNavigationStack(callee: String, node: FunctionCallExprSyntax) {
            guard callee == "NavigationStack", containerStack.contains("NavigationStack") else { return }
            violations.append(ReasonedRuleViolation(
                position: node.positionAfterSkippingLeadingTrivia,
                reason: "Nested NavigationStack — causes double navigation bars and broken navigation",
                severity: .error,
                confidence: .high,
                suggestion: "Remove the inner NavigationStack; only the root view should own one"
            ))
        }

        private func checkListInsideScrollView(callee: String, node: FunctionCallExprSyntax) {
            guard callee == "List", containerStack.contains("ScrollView") else { return }
            violations.append(ReasonedRuleViolation(
                position: node.positionAfterSkippingLeadingTrivia,
                reason: "List inside ScrollView — List has built-in scrolling, nesting causes conflicts",
                severity: .error,
                confidence: .high,
                suggestion: "Remove the outer ScrollView or replace List with ForEach"
            ))
        }

        private func checkGeometryReaderInsideScrollView(callee: String, node: FunctionCallExprSyntax) {
            guard callee == "GeometryReader", containerStack.contains("ScrollView") else { return }
            violations.append(ReasonedRuleViolation(
                position: node.positionAfterSkippingLeadingTrivia,
                reason: "GeometryReader inside ScrollView — proposed size is undefined in the scroll axis",
                severity: .error,
                confidence: .high,
                suggestion: "Move GeometryReader outside the ScrollView or use a fixed frame"
            ))
        }

        private func checkMultipleUnboundedContainers(node: FunctionCallExprSyntax) {
            guard let current = containerStack.last, Self.unboundedContainers.contains(current) else { return }
            guard let stackIndex = containerStack.dropLast().lastIndex(where: { Self.stackContainers.contains($0) })
            else { return }

            let childrenAfterStack = containerStack[(stackIndex + 1)...]
            let hasInterveningStack = childrenAfterStack.dropLast().contains { Self.stackContainers.contains($0) }
            guard !hasInterveningStack else { return }

            let unboundedCount = childrenAfterStack.filter { Self.unboundedContainers.contains($0) }.count
            guard unboundedCount >= 2 else { return }

            let stackName = containerStack[stackIndex]
            violations.append(ReasonedRuleViolation(
                position: node.positionAfterSkippingLeadingTrivia,
                reason: "Multiple unbounded containers (\(unboundedCount)) inside \(stackName) — they compete for space",
                severity: .warning,
                confidence: .medium,
                suggestion: "Give explicit frames to each container or restructure the layout"
            ))
        }
    }
}
