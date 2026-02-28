import SwiftSyntax

struct TypedThrowsRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "typed_throws",
        name: "Typed Throws",
        description: "Functions that throw a single error type should use typed throws",
        kind: .suggest,
        nonTriggeringExamples: [
            Example("func parse() throws(ParseError) { throw ParseError.invalid }"),
            Example("func work() throws { throw ErrorA.a; throw ErrorB.b }"),
            Example("func safe() { }"),
        ],
        triggeringExamples: [
            Example("↓func parse() throws { throw ParseError.invalid }"),
        ]
    )
}

extension TypedThrowsRule: SwiftSyntaxRule {
    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor<ConfigurationType> {
        Visitor(configuration: configuration, file: file)
    }
}

extension TypedThrowsRule: OptInRule {}

private extension TypedThrowsRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionDeclSyntax) {
            guard let throwsClause = node.signature.effectSpecifiers?.throwsClause,
                  throwsClause.type == nil,
                  let body = node.body
            else { return }

            let collector = ThrowCollector(viewMode: .sourceAccurate)
            collector.walk(body)

            guard !collector.thrownTypes.isEmpty,
                  !collector.thrownTypes.contains("__unknown__"),
                  collector.thrownTypes.count == 1,
                  let errorType = collector.thrownTypes.first
            else { return }

            let funcName = node.name.text
            violations.append(
                ReasonedRuleViolation(
                    position: node.positionAfterSkippingLeadingTrivia,
                    reason: "Function '\(funcName)' throws only '\(errorType)' but declares untyped 'throws'",
                    severity: .warning,
                    confidence: collector.hasRethrows ? .medium : .high,
                    suggestion: "func \(funcName)(...) throws(\(errorType))"
                )
            )
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            guard let throwsClause = node.signature.effectSpecifiers?.throwsClause,
                  throwsClause.type == nil,
                  let body = node.body
            else { return }

            let collector = ThrowCollector(viewMode: .sourceAccurate)
            collector.walk(body)

            guard !collector.thrownTypes.isEmpty,
                  !collector.thrownTypes.contains("__unknown__"),
                  collector.thrownTypes.count == 1,
                  let errorType = collector.thrownTypes.first
            else { return }

            violations.append(
                ReasonedRuleViolation(
                    position: node.positionAfterSkippingLeadingTrivia,
                    reason: "Initializer throws only '\(errorType)' but declares untyped 'throws'",
                    severity: .warning,
                    confidence: collector.hasRethrows ? .medium : .high,
                    suggestion: "init(...) throws(\(errorType))"
                )
            )
        }
    }
}
