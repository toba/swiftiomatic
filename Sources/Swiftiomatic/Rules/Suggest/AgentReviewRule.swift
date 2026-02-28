import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct AgentReviewRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "agent_review",
        name: "Agent Review",
        description: "Lower-confidence checks that benefit from agent verification",
        kind: .lint,
        nonTriggeringExamples: [
            Example("let task = Task { await work() }"),
            Example("enum AppError: LocalizedError { case failed }"),
        ],
        triggeringExamples: [
            Example("↓Task { await work() }"),
            Example("enum ↓AppError: Error { case failed }"),
        ]
    )
}

private extension AgentReviewRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            let callee = node.calledExpression.trimmedDescription

            // Fire-and-forget Task {}
            if callee == "Task" || callee == "Task.detached" {
                let isAssigned = node.parent?.is(InitializerClauseSyntax.self) == true
                    || node.parent?.is(AssignmentExprSyntax.self) == true
                    || node.parent?.is(PatternBindingSyntax.self) == true
                let isReturned = node.parent?.is(ReturnStmtSyntax.self) == true

                if !isAssigned && !isReturned {
                    violations.append(ReasonedRuleViolation(
                        position: node.positionAfterSkippingLeadingTrivia,
                        reason: "Fire-and-forget Task — result not captured, cancellation not possible",
                        severity: .warning,
                        confidence: .low,
                        suggestion: "Assign to a variable if cancellation matters: `let task = Task { ... }`"
                    ))
                }
            }

            // .absoluteString usage
            if callee.hasSuffix(".absoluteString") {
                violations.append(ReasonedRuleViolation(
                    position: node.positionAfterSkippingLeadingTrivia,
                    reason: ".absoluteString used — verify this isn't a file URL (use .path for file URLs)",
                    severity: .warning,
                    confidence: .low
                ))
            }
        }

        override func visitPost(_ node: MemberAccessExprSyntax) {
            if node.declName.baseName.text == "absoluteString",
               node.parent?.is(FunctionCallExprSyntax.self) != true {
                violations.append(ReasonedRuleViolation(
                    position: node.positionAfterSkippingLeadingTrivia,
                    reason: ".absoluteString used — verify this isn't a file URL (use .path for file URLs)",
                    severity: .warning,
                    confidence: .low
                ))
            }
        }

        override func visitPost(_ node: EnumDeclSyntax) {
            guard let inheritance = node.inheritanceClause else { return }
            let inheritedTypes = inheritance.inheritedTypes.map { $0.type.trimmedDescription }
            if inheritedTypes.contains("Error") && !inheritedTypes.contains("LocalizedError") {
                violations.append(ReasonedRuleViolation(
                    position: node.name.positionAfterSkippingLeadingTrivia,
                    reason: "Error enum '\(node.name.text)' doesn't conform to LocalizedError — verify if user-facing",
                    severity: .warning,
                    confidence: .low,
                    suggestion: "Add LocalizedError conformance with errorDescription"
                ))
            }
        }

        override func visitPost(_ node: VariableDeclSyntax) {
            let modifiers = node.modifiers.map { $0.trimmedDescription }
            if modifiers.contains("nonisolated(unsafe)") {
                let bindingName = node.bindings.first?.pattern.trimmedDescription ?? "unknown"
                violations.append(ReasonedRuleViolation(
                    position: node.positionAfterSkippingLeadingTrivia,
                    reason: "nonisolated(unsafe) on '\(bindingName)' — verify the value is actually Sendable in Swift 6.2",
                    severity: .warning,
                    confidence: .low
                ))
            }
        }
    }
}
