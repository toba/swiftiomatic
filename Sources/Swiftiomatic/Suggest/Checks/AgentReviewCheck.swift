import SwiftSyntax

/// §8: Lower-confidence checks that need agent verification.
public final class AgentReviewCheck: BaseCheck {

    // MARK: - 8b: Fire-and-forget Task {}

    override public func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let callee = node.calledExpression.trimmedDescription

        // Unassigned Task { }
        if callee == "Task" || callee == "Task.detached" {
            // Check if the Task result is captured
            let isAssigned = node.parent?.is(InitializerClauseSyntax.self) == true
                || node.parent?.is(AssignmentExprSyntax.self) == true
                || node.parent?.is(PatternBindingSyntax.self) == true
                || node.parent?.as(SequenceExprSyntax.self)?.elements.contains(where: {
                    $0.is(AssignmentExprSyntax.self)
                }) == true

            if !isAssigned {
                // Check if parent is a return statement or variable binding
                let isReturned = node.parent?.is(ReturnStmtSyntax.self) == true

                if !isReturned {
                    addFinding(
                        at: node,
                        category: .agentReview,
                        severity: .low,
                        message: "Fire-and-forget Task — result not captured, cancellation not possible",
                        suggestion: "Assign to a variable if cancellation matters: `let task = Task { ... }`",
                        confidence: .low
                    )
                }
            }
        }

        // 8f: .absoluteString usage
        if callee.hasSuffix(".absoluteString") {
            addFinding(
                at: node,
                category: .agentReview,
                severity: .low,
                message: ".absoluteString used — verify this isn't a file URL (use .path for file URLs)",
                confidence: .low
            )
        }

        return .visitChildren
    }

    // MARK: - 8b: Fire-and-forget via MemberAccessExpr

    override public func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        // 8f: .absoluteString
        if node.declName.baseName.text == "absoluteString" {
            // Only flag if it's not already caught as a function call
            if node.parent?.is(FunctionCallExprSyntax.self) != true {
                addFinding(
                    at: node,
                    category: .agentReview,
                    severity: .low,
                    message: ".absoluteString used — verify this isn't a file URL (use .path for file URLs)",
                    confidence: .low
                )
            }
        }

        return .visitChildren
    }

    // MARK: - 8c: .onAppear + Task (should be .task modifier)

    override public func visit(_ node: LabeledExprSyntax) -> SyntaxVisitorContinueKind {
        // This is a heuristic — look for .onAppear closures containing Task {}
        return .visitChildren
    }

    // MARK: - 8d: Error enums without LocalizedError

    override public func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let inheritance = node.inheritanceClause else { return .visitChildren }
        let inheritedTypes = inheritance.inheritedTypes.map { $0.type.trimmedDescription }

        if inheritedTypes.contains("Error") && !inheritedTypes.contains("LocalizedError") {
            addFinding(
                at: node,
                category: .agentReview,
                severity: .low,
                message: "Error enum '\(node.name.text)' doesn't conform to LocalizedError — verify if user-facing",
                suggestion: "Add LocalizedError conformance with errorDescription",
                confidence: .low
            )
        }

        return .visitChildren
    }

    // MARK: - 8g: nonisolated(unsafe) let

    override public func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        let modifiers = node.modifiers.map { $0.trimmedDescription }
        if modifiers.contains("nonisolated(unsafe)") {
            let bindingName = node.bindings.first?.pattern.trimmedDescription ?? "unknown"
            addFinding(
                at: node,
                category: .agentReview,
                severity: .low,
                message: "nonisolated(unsafe) on '\(bindingName)' — verify the value is actually Sendable in Swift 6.2",
                confidence: .low
            )
        }

        return .visitChildren
    }
}
