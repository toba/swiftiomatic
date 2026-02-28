import SwiftSyntax

struct Swift62ModernizationRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "swift62_modernization",
        name: "Swift 6.2 Modernization",
        description:
        "Code that can benefit from Swift 6.2 features like @concurrent, Observations, weak let, and Span",
        kind: .suggest,
        nonTriggeringExamples: [
            Example("func work() async { }"),
        ],
        triggeringExamples: [
            Example("↓Task.detached { await work() }"),
            Example("↓withObservationTracking { }"),
        ],
    )
}

extension Swift62ModernizationRule: SwiftSyntaxRule {
    func makeVisitor(file: SwiftSource) -> ViolationsSyntaxVisitor<ConfigurationType> {
        Visitor(configuration: configuration, file: file)
    }
}

extension Swift62ModernizationRule: OptInRule {}

private extension Swift62ModernizationRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            let callee = node.calledExpression.trimmedDescription

            if callee == "Task.detached" {
                violations.append(
                    SyntaxViolation(
                        position: node.positionAfterSkippingLeadingTrivia,
                        reason: "Task.detached may be replaceable with @concurrent",
                        severity: .warning,
                        confidence: .low,
                        suggestion:
                        "Use @concurrent on an async function instead — but note @concurrent inherits @TaskLocal values while Task.detached drops them",
                    ),
                )
            }

            if callee == "withObservationTracking" {
                violations.append(
                    SyntaxViolation(
                        position: node.positionAfterSkippingLeadingTrivia,
                        reason:
                        "withObservationTracking can be replaced with Observations AsyncSequence in Swift 6.2",
                        severity: .warning,
                        confidence: .medium,
                        suggestion: "for await value in Observations { ... }",
                    ),
                )
            }
        }

        override func visitPost(_ node: VariableDeclSyntax) {
            let hasWeak = node.modifiers.contains { $0.name.text == "weak" }
            guard hasWeak, node.bindingSpecifier.tokenKind == .keyword(.var) else { return }

            let bindingName = node.bindings.first?.pattern.trimmedDescription ?? "unknown"
            violations.append(
                SyntaxViolation(
                    position: node.positionAfterSkippingLeadingTrivia,
                    reason:
                    "weak var '\(bindingName)' — if never reassigned after init, use weak let (SE-0481)",
                    severity: .warning,
                    confidence: .low,
                ),
            )
        }

        override func visitPost(_ node: TypeAnnotationSyntax) {
            let typeStr = node.type.trimmedDescription
            if typeStr.contains("UnsafeRawBufferPointer")
                || typeStr.contains("UnsafeBufferPointer")
                || typeStr.contains("UnsafeMutableRawBufferPointer")
                || typeStr.contains("UnsafeMutableBufferPointer")
            {
                violations.append(
                    SyntaxViolation(
                        position: node.positionAfterSkippingLeadingTrivia,
                        reason: "Unsafe buffer pointer — consider Span/RawSpan (macOS 26.0+)",
                        severity: .warning,
                        confidence: .low,
                        suggestion: "Use Span<T> or RawSpan for safe, non-owning buffer access",
                    ),
                )
            }
        }

        override func visitPost(_ node: AccessorDeclSyntax) {
            let accessorKind = node.accessorSpecifier.text
            guard accessorKind == "didSet" || accessorKind == "willSet",
                  let body = node.body, body.statements.count > 1
            else { return }

            violations.append(
                SyntaxViolation(
                    position: node.positionAfterSkippingLeadingTrivia,
                    reason:
                    "\(accessorKind) with side-effect logic — consider Observations framework if on an @Observable type",
                    severity: .warning,
                    confidence: .low,
                ),
            )
        }
    }
}
