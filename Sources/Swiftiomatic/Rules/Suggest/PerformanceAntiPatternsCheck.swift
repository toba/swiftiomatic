import SwiftSyntax

/// §5: Finds common performance anti-patterns.
final class PerformanceAntiPatternsCheck: BaseCheck {
    // MARK: - Date() for benchmarking

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let callee = node.calledExpression.trimmedDescription

        // Date() used near timing patterns
        if callee == "Date" || callee == "Date.init" {
            if let parent = node.parent,
               parent.trimmedDescription.contains("timeIntervalSince")
               || parent.trimmedDescription.contains("elapsed")
               || parent.trimmedDescription.contains("start")
               || parent.trimmedDescription.contains("duration")
            {
                addFinding(
                    at: node,
                    category: .performanceAntiPatterns,
                    severity: .low,
                    message: "Date() used for timing — can go backwards due to NTP adjustments",
                    suggestion: "Use ContinuousClock.now for monotonic timing",
                    confidence: .medium,
                )
            }
        }

        return .visitChildren
    }

    // MARK: - Mutation during iteration (for-in + remove/insert)

    override func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind {
        guard let sequenceExpr = node.sequence.as(DeclReferenceExprSyntax.self) else {
            return .visitChildren
        }
        let collectionName = sequenceExpr.baseName.text

        let mutationFinder = MutationDuringIterationFinder(
            collectionName: collectionName,
            viewMode: .sourceAccurate,
        )
        mutationFinder.walk(node.body)

        if mutationFinder.foundMutation {
            addFinding(
                at: node,
                category: .performanceAntiPatterns,
                severity: .high,
                message:
                "Collection '\(collectionName)' is mutated during iteration — may crash or skip elements",
                suggestion: "Use removeAll(where:), filter, or collect indices first",
                confidence: .high,
            )
        }

        return .skipChildren
    }

    // MARK: - Empty/single-element array literals for Collection/Sequence params

    override func visit(_ node: ArrayExprSyntax) -> SyntaxVisitorContinueKind {
        let elementCount = node.elements.count

        guard elementCount <= 1 else { return .visitChildren }

        if node.parent?.is(LabeledExprSyntax.self) == true {
            let label = elementCount == 0 ? "EmptyCollection()" : "CollectionOfOne(...)"
            addFinding(
                at: node,
                category: .performanceAntiPatterns,
                severity: .low,
                message: elementCount == 0
                    ? "Empty array literal may heap-allocate when passed to generic Collection/Sequence parameter"
                    :
                    "Single-element array literal may heap-allocate when passed to generic Collection/Sequence parameter",
                suggestion: "Consider \(label) for zero-allocation alternative",
                confidence: .low,
            )
        }

        return .visitChildren
    }
}
