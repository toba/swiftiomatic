import Foundation
import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct NamingHeuristicsRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "naming_heuristics",
        name: "Naming Heuristics",
        description: "Checks names against Swift API Design Guidelines: Bool assertions, protocol suffixes, factory prefixes",
        kind: .style,
        nonTriggeringExamples: [
            Example("var isEnabled: Bool = true"),
            Example("var hasContent: Bool = false"),
            Example("static func makeWidget() -> Widget { }"),
        ],
        triggeringExamples: [
            Example("var ↓enabled: Bool = true"),
            Example("static func ↓createWidget() -> Widget { }"),
        ]
    )
}

private extension NamingHeuristicsRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: ProtocolDeclSyntax) {
            let name = node.name.text
            guard name.hasSuffix("able") || name.hasSuffix("ible") else { return }

            let methods = node.memberBlock.members.compactMap { $0.decl.as(FunctionDeclSyntax.self) }
            let hasActionVerbs = methods.contains { method in
                let n = method.name.text
                return n.hasPrefix("provide") || n.hasPrefix("supply")
                    || n.hasPrefix("create") || n.hasPrefix("generate")
                    || n.hasPrefix("load") || n.hasPrefix("fetch")
                    || n.hasPrefix("report") || n.hasPrefix("coordinate")
            }

            if hasActionVerbs {
                violations.append(ReasonedRuleViolation(
                    position: node.name.positionAfterSkippingLeadingTrivia,
                    reason: "Protocol '\(name)' uses -able suffix but conformers perform the action — consider -ing suffix",
                    severity: .warning,
                    confidence: .low,
                    suggestion: name.replacingSuffix("able", with: "ing")
                        ?? name.replacingSuffix("ible", with: "ing")
                ))
            }
        }

        override func visitPost(_ node: VariableDeclSyntax) {
            for binding in node.bindings {
                guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else { continue }
                let name = pattern.identifier.text

                if let typeAnnotation = binding.typeAnnotation,
                   typeAnnotation.type.trimmedDescription == "Bool" {
                    checkBoolNaming(name: name, position: pattern.positionAfterSkippingLeadingTrivia)
                }
            }
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            let name = node.name.text
            guard node.modifiers.contains(where: { $0.name.text == "static" }) else { return }

            let hasCreatePrefix = name.hasPrefix("create") || name.hasPrefix("new") || name.hasPrefix("build")
            guard hasCreatePrefix else { return }

            let stripped: String
            if name.hasPrefix("create") { stripped = String(name.dropFirst(6)) }
            else if name.hasPrefix("new") { stripped = String(name.dropFirst(3)) }
            else { stripped = String(name.dropFirst(5)) }

            violations.append(ReasonedRuleViolation(
                position: node.name.positionAfterSkippingLeadingTrivia,
                reason: "Factory method '\(name)' should use 'make' prefix per Swift API Design Guidelines",
                severity: .warning,
                confidence: .medium,
                suggestion: "make\(stripped)"
            ))
        }

        private func checkBoolNaming(name: String, position: AbsolutePosition) {
            let assertionPrefixes = [
                "is", "has", "can", "should", "will", "did", "was",
                "needs", "allows", "requires", "supports", "includes",
                "contains", "enables",
            ]
            let startsWithAssertion = assertionPrefixes.contains { prefix in
                name.hasPrefix(prefix) && name.count > prefix.count
                    && name[name.index(name.startIndex, offsetBy: prefix.count)].isUppercase
            }

            if !startsWithAssertion && !name.hasPrefix("_") {
                violations.append(ReasonedRuleViolation(
                    position: position,
                    reason: "Bool property '\(name)' doesn't read as an assertion",
                    severity: .warning,
                    confidence: .low,
                    suggestion: "Consider a name like 'is\(name.capitalized)' or 'has\(name.capitalized)'"
                ))
            }
        }
    }
}
