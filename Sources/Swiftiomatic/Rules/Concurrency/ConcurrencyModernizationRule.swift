import SwiftSyntax

struct ConcurrencyModernizationRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "concurrency_modernization",
        name: "Concurrency Modernization",
        description: "Flags GCD usage and legacy concurrency patterns that should use structured concurrency",
        kind: .concurrency,
        nonTriggeringExamples: [
            Example("Task { @MainActor in update() }"),
            Example("await withTaskGroup(of: Void.self) { }"),
        ],
        triggeringExamples: [
            Example("↓DispatchQueue.main.async { update() }"),
            Example("↓DispatchGroup()"),
            Example("func fetch(↓completion: @escaping (Result<Data, Error>) -> Void) {}"),
        ]
    )
}

extension ConcurrencyModernizationRule: SwiftSyntaxRule {
    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor<ConfigurationType> {
        Visitor(configuration: configuration, file: file)
    }
}

extension ConcurrencyModernizationRule: OptInRule {}

private extension ConcurrencyModernizationRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionDeclSyntax) {
            for param in node.signature.parameterClause.parameters {
                let paramName = param.firstName.text
                let isCompletion = paramName == "completion" || paramName == "completionHandler"
                    || paramName == "handler" || paramName == "callback"

                if isCompletion, param.type.trimmedDescription.contains("@escaping") {
                    violations.append(ReasonedRuleViolation(
                        position: node.positionAfterSkippingLeadingTrivia,
                        reason: "Function '\(node.name.text)' uses completion handler pattern",
                        severity: .warning,
                        confidence: .high,
                        suggestion: "Convert to async/await"
                    ))
                    break
                }
            }
        }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            let callee = node.calledExpression.trimmedDescription

            if callee.contains("DispatchQueue") && callee.hasSuffix(".async") {
                violations.append(ReasonedRuleViolation(
                    position: node.positionAfterSkippingLeadingTrivia,
                    reason: "DispatchQueue.async can be replaced with structured concurrency",
                    severity: .warning,
                    confidence: .medium,
                    suggestion: "Use Task { @MainActor in ... } or async function"
                ))
            }

            if callee.contains("DispatchGroup") {
                violations.append(ReasonedRuleViolation(
                    position: node.positionAfterSkippingLeadingTrivia,
                    reason: "DispatchGroup can be replaced with TaskGroup",
                    severity: .warning,
                    confidence: .medium,
                    suggestion: "Use withTaskGroup or withThrowingTaskGroup"
                ))
            }

            if callee.contains("NSLock()") || callee.contains("os_unfair_lock") {
                violations.append(ReasonedRuleViolation(
                    position: node.positionAfterSkippingLeadingTrivia,
                    reason: "Lock-based synchronization can be replaced with Mutex",
                    severity: .warning,
                    confidence: .medium,
                    suggestion: "Use Mutex<Value> for state protection"
                ))
            }
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            if let clause = node.inheritanceClause, clause.trimmedDescription.contains("@unchecked Sendable") {
                violations.append(ReasonedRuleViolation(
                    position: node.positionAfterSkippingLeadingTrivia,
                    reason: "Class '\(node.name.text)' uses @unchecked Sendable — check if Mutex would enable proper Sendable",
                    severity: .warning,
                    confidence: .low
                ))
            }
        }
    }
}
