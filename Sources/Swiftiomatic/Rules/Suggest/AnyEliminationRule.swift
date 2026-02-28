import SwiftSyntax

struct AnyEliminationRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "any_elimination",
        name: "Any Elimination",
        description: "Usage of Any/AnyObject erases type safety and should be replaced with specific types or generics",
        kind: .suggest,
        nonTriggeringExamples: [
            Example("var name: String = \"\""),
            Example("func process(_ item: Codable) {}"),
        ],
        triggeringExamples: [
            Example("var value: ↓Any = 0"),
            Example("func process(_ dict: ↓[String: Any]) {}"),
            Example("let x = value ↓as! String"),
        ]
    )
}

extension AnyEliminationRule: SwiftSyntaxRule {
    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor<ConfigurationType> {
        Visitor(configuration: configuration, file: file)
    }
}

extension AnyEliminationRule: OptInRule {}

private extension AnyEliminationRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: TypeAnnotationSyntax) {
            checkForAny(in: node.type, at: node)
        }

        override func visitPost(_ node: ReturnClauseSyntax) {
            checkForAny(in: node.type, at: node)
        }

        override func visitPost(_ node: DictionaryTypeSyntax) {
            let key = node.key.trimmedDescription
            let value = node.value.trimmedDescription
            if key == "String" && (value == "Any" || value == "any Sendable") {
                violations.append(ReasonedRuleViolation(
                    position: node.positionAfterSkippingLeadingTrivia,
                    reason: "[String: \(value)] dictionary should be a Codable struct",
                    severity: .warning,
                    confidence: .medium,
                    suggestion: "Define a struct with typed properties instead"
                ))
            }
        }

        override func visitPost(_ node: AsExprSyntax) {
            if node.questionOrExclamationMark?.tokenKind == .exclamationMark {
                violations.append(ReasonedRuleViolation(
                    position: node.positionAfterSkippingLeadingTrivia,
                    reason: "Force cast 'as!' — trace back to where the type was erased",
                    severity: .warning,
                    confidence: .medium,
                    suggestion: "Use generics or a typed API to avoid the cast"
                ))
            }
        }

        private func checkForAny(in type: TypeSyntax, at node: some SyntaxProtocol) {
            let typeStr = type.trimmedDescription
            if typeStr == "Any" || typeStr == "Any?" {
                violations.append(ReasonedRuleViolation(
                    position: type.positionAfterSkippingLeadingTrivia,
                    reason: "Type 'Any' erases type safety",
                    severity: .warning,
                    confidence: .medium,
                    suggestion: "Use a specific type, protocol, or generic parameter"
                ))
            } else if typeStr == "AnyObject" || typeStr == "AnyObject?" {
                violations.append(ReasonedRuleViolation(
                    position: type.positionAfterSkippingLeadingTrivia,
                    reason: "Type 'AnyObject' — consider a specific class type or protocol",
                    severity: .warning,
                    confidence: .low
                ))
            } else if typeStr == "AnyHashable" {
                violations.append(ReasonedRuleViolation(
                    position: type.positionAfterSkippingLeadingTrivia,
                    reason: "Type 'AnyHashable' — check if all elements share a common concrete type",
                    severity: .warning,
                    confidence: .low
                ))
            }
        }
    }
}
