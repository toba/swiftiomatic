import SwiftSyntax

struct ClosureBodyLengthRule: Rule {
    private static let defaultWarningThreshold = 30

    var configuration = SeverityLevelsConfiguration<Self>(
        warning: Self.defaultWarningThreshold, error: 100,
    )

    static let description = RuleDescription(
        identifier: "closure_body_length",
        name: "Closure Body Length",
        description: "Closure bodies should not span too many lines",
        rationale: """
        "Closure bodies should not span too many lines" says it all.

        Possibly you could refactor your closure code and extract some of it into a function.
        """,
        kind: .metrics,
        nonTriggeringExamples: ClosureBodyLengthRuleExamples.nonTriggeringExamples,
        triggeringExamples: ClosureBodyLengthRuleExamples.triggeringExamples,
    )
}

extension ClosureBodyLengthRule: SwiftSyntaxRule {
    func makeVisitor(file: SwiftSource) -> ViolationsSyntaxVisitor<ConfigurationType> {
        Visitor(configuration: configuration, file: file)
    }
}

extension ClosureBodyLengthRule: OptInRule {}

private extension ClosureBodyLengthRule {
    final class Visitor: BodyLengthVisitor<ConfigurationType> {
        override func visitPost(_ node: ClosureExprSyntax) {
            registerViolations(
                leftBrace: node.leftBrace,
                rightBrace: node.rightBrace,
                violationNode: node.leftBrace,
                objectName: "Closure",
            )
        }
    }
}
