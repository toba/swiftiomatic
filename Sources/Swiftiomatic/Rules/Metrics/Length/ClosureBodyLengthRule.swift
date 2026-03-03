import SwiftSyntax

struct ClosureBodyLengthRule {
    static let id = "closure_body_length"
    static let name = "Closure Body Length"
    static let summary = "Closure bodies should not span too many lines"
    static let isOptIn = true
    static let rationale: String? = """
    "Closure bodies should not span too many lines" says it all.

    Possibly you could refactor your closure code and extract some of it into a function.
    """
    private static let defaultWarningThreshold = 30

    var options = SeverityLevelsConfiguration<Self>(
        warning: Self.defaultWarningThreshold, error: 100,
    )
}

extension ClosureBodyLengthRule: SwiftSyntaxRule {
    func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
        Visitor(configuration: options, file: file)
    }
}

extension ClosureBodyLengthRule {
    fileprivate final class Visitor: BodyLengthVisitor<OptionsType> {
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
