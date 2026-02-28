import SwiftSyntax

/// §8: Lower-confidence checks that need agent verification.
final class AgentReviewCheck: BaseCheck {
    // MARK: - 8f: .absoluteString usage

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let callee = node.calledExpression.trimmedDescription

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

    // MARK: - 8f: .absoluteString via MemberAccessExpr

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        if node.declName.baseName.text == "absoluteString" {
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

    // MARK: - 8d: Error enums without LocalizedError

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let inheritance = node.inheritanceClause else { return .visitChildren }
        let inheritedTypes = inheritance.inheritedTypes.map(\.type.trimmedDescription)

        if inheritedTypes.contains("Error") && !inheritedTypes.contains("LocalizedError") {
            addFinding(
                at: node,
                category: .agentReview,
                severity: .low,
                message:
                "Error enum '\(node.name.text)' doesn't conform to LocalizedError — verify if user-facing",
                suggestion: "Add LocalizedError conformance with errorDescription",
                confidence: .low
            )
        }

        return .visitChildren
    }

    // MARK: - 8g: nonisolated(unsafe) let

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        let modifiers = node.modifiers.map(\.trimmedDescription)
        if modifiers.contains("nonisolated(unsafe)") {
            let bindingName = node.bindings.first?.pattern.trimmedDescription ?? "unknown"
            addFinding(
                at: node,
                category: .agentReview,
                severity: .low,
                message:
                "nonisolated(unsafe) on '\(bindingName)' — verify the value is actually Sendable in Swift 6.2",
                confidence: .low
            )
        }

        return .visitChildren
    }
}
