import SwiftSyntax

/// §7: Finds common pitfalls with the Observation framework.
public final class ObservationPitfallsCheck: BaseCheck {

    // MARK: - withObservationTracking that should be Observations

    override public func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let callee = node.calledExpression.trimmedDescription

        if callee == "withObservationTracking" {
            addFinding(
                at: node,
                category: .observationPitfalls,
                severity: .medium,
                message: "withObservationTracking with recursive onChange — consider Observations AsyncSequence",
                suggestion: "Replace with `for await value in Observations { ... }`",
                confidence: .medium
            )
        }

        return .visitChildren
    }

    // MARK: - Observations missing weak self

    override public func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind {
        // Look for `for await ... in Observations { ... }`
        guard let callExpr = node.sequence.as(FunctionCallExprSyntax.self),
              callExpr.calledExpression.trimmedDescription == "Observations"
        else {
            return .visitChildren
        }

        // Check for [weak self] in the trailing closure
        if let trailingClosure = callExpr.trailingClosure {
            let hasWeakSelf = trailingClosure.signature?.capture?.items.contains { item in
                item.trimmedDescription.contains("weak self")
            } ?? false

            if !hasWeakSelf {
                addFinding(
                    at: callExpr,
                    category: .observationPitfalls,
                    severity: .high,
                    message: "Observations closure missing [weak self] — may cause retain cycle",
                    suggestion: "Add [weak self] to the Observations closure",
                    confidence: .medium
                )
            }
        }

        return .visitChildren
    }
}
