import SwiftSyntax

struct EmptyStringRule {
    static let id = "empty_string"
    static let name = "Empty String"
    static let summary =
        "Prefer checking `isEmpty` over comparing `string` to an empty string literal"
    static let isOptIn = true
    static var nonTriggeringExamples: [Example] {
        [
            Example("myString.isEmpty"),
            Example("!myString.isEmpty"),
            Example("\"\"\"\nfoo==\n\"\"\""),
        ]
    }

    static var triggeringExamples: [Example] {
        [
            Example(#"myString↓ == """#),
            Example(#"myString↓ != """#),
            Example(#"myString↓=="""#),
            Example(##"myString↓ == #""#"##),
            Example(###"myString↓ == ##""##"###),
        ]
    }

    var options = SeverityOption<Self>(.warning)
}

extension EmptyStringRule {
    fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
        override func visitPost(_ node: StringLiteralExprSyntax) {
            guard
                // Empty string literal: `""`, `#""#`, etc.
                node.segments.onlyElement?.trimmedLength == .zero,
                let previousToken = node.previousToken(viewMode: .sourceAccurate),
                // On the rhs of an `==` or `!=` operator
                previousToken.tokenKind.isEqualityComparison,
                let secondPreviousToken = previousToken.previousToken(viewMode: .sourceAccurate)
            else {
                return
            }

            let violationPosition = secondPreviousToken.endPositionBeforeTrailingTrivia
            violations.append(violationPosition)
        }
    }
}

extension EmptyStringRule: SwiftSyntaxRule {
    func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
        Visitor(configuration: options, file: file)
    }
}
