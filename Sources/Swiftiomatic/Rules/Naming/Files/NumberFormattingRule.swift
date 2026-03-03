import SwiftSyntax

struct NumberFormattingRule {
    static let id = "number_formatting"
    static let name = "Number Formatting"
    static let summary = "Large numeric literals should use underscores for grouping"
    static let scope: Scope = .suggest
    static var nonTriggeringExamples: [Example] {
        [
            Example("let x = 1_000_000"),
            Example("let x = 100"),
            Example("let x = 0xFF"),
            Example("let x = 1_000"),
        ]
    }

    static var triggeringExamples: [Example] {
        [
            Example("let x = ↓1000000"),
            Example("let x = ↓100000"),
        ]
    }

    var options = SeverityOption<Self>(.warning)
}

extension NumberFormattingRule: SwiftSyntaxRule {
    func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
        Visitor(configuration: options, file: file)
    }
}

extension NumberFormattingRule {
    fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
        override func visitPost(_ node: IntegerLiteralExprSyntax) {
            let literal = node.literal.text

            // Skip hex, binary, octal literals
            guard !literal.hasPrefix("0x"), !literal.hasPrefix("0b"),
                  !literal.hasPrefix("0o")
            else {
                return
            }

            // Skip if already has separators
            guard !literal.contains("_") else { return }

            // Flag if >= 5 digits (threshold for readability)
            let digits = literal.filter(\.isNumber)
            guard digits.count >= 5 else { return }

            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}
