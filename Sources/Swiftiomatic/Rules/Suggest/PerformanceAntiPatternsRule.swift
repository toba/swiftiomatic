import SwiftSyntax

struct PerformanceAntiPatternsRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "performance_anti_patterns",
        name: "Performance Anti-Patterns",
        description: "Detects common performance anti-patterns like Date() for benchmarking and mutation during iteration",
        kind: .performance,
        nonTriggeringExamples: [
            Example("let now = ContinuousClock.now"),
            Example("array.removeAll(where: { $0.isEmpty })"),
        ],
        triggeringExamples: [
            Example("""
            for item in ↓items {
                items.remove(at: 0)
            }
            """),
        ]
    )
}

extension PerformanceAntiPatternsRule: SwiftSyntaxRule {
    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor<ConfigurationType> {
        Visitor(configuration: configuration, file: file)
    }
}

extension PerformanceAntiPatternsRule: OptInRule {}

private extension PerformanceAntiPatternsRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            let callee = node.calledExpression.trimmedDescription
            if callee == "Date" || callee == "Date.init" {
                if let parent = node.parent,
                   parent.trimmedDescription.contains("timeIntervalSince")
                    || parent.trimmedDescription.contains("elapsed")
                    || parent.trimmedDescription.contains("start")
                    || parent.trimmedDescription.contains("duration")
                {
                    violations.append(ReasonedRuleViolation(
                        position: node.positionAfterSkippingLeadingTrivia,
                        reason: "Date() used for timing — can go backwards due to NTP adjustments",
                        severity: .warning,
                        confidence: .medium,
                        suggestion: "Use ContinuousClock.now for monotonic timing"
                    ))
                }
            }
        }

        override func visitPost(_ node: ForStmtSyntax) {
            guard let sequenceExpr = node.sequence.as(DeclReferenceExprSyntax.self) else { return }
            let collectionName = sequenceExpr.baseName.text

            let mutationFinder = MutationFinder(collectionName: collectionName, viewMode: .sourceAccurate)
            mutationFinder.walk(node.body)

            if mutationFinder.foundMutation {
                violations.append(ReasonedRuleViolation(
                    position: node.positionAfterSkippingLeadingTrivia,
                    reason: "Collection '\(collectionName)' is mutated during iteration — may crash or skip elements",
                    severity: .error,
                    confidence: .high,
                    suggestion: "Use removeAll(where:), filter, or collect indices first"
                ))
            }
        }

        override func visitPost(_ node: ArrayExprSyntax) {
            let elementCount = node.elements.count
            guard elementCount <= 1, node.parent?.is(LabeledExprSyntax.self) == true else { return }

            let label = elementCount == 0 ? "EmptyCollection()" : "CollectionOfOne(...)"
            violations.append(ReasonedRuleViolation(
                position: node.positionAfterSkippingLeadingTrivia,
                reason: elementCount == 0
                    ? "Empty array literal may heap-allocate when passed to generic Collection/Sequence parameter"
                    : "Single-element array literal may heap-allocate when passed to generic Collection/Sequence parameter",
                severity: .warning,
                confidence: .low,
                suggestion: "Consider \(label) for zero-allocation alternative"
            ))
        }
    }
}

private final class MutationFinder: SyntaxVisitor {
    let collectionName: String
    var foundMutation = false

    init(collectionName: String, viewMode: SyntaxTreeViewMode) {
        self.collectionName = collectionName
        super.init(viewMode: viewMode)
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let callee = node.calledExpression.trimmedDescription
        let mutatingMethods = [
            "\(collectionName).remove", "\(collectionName).insert",
            "\(collectionName).append", "\(collectionName).removeAll",
        ]
        if mutatingMethods.contains(where: { callee.hasPrefix($0) }) {
            foundMutation = true
        }
        return .visitChildren
    }
}
