import SwiftSyntax

struct NumberFormattingRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "number_formatting",
    name: "Number Formatting",
    description: "Large numeric literals should use underscores for grouping",
    scope: .suggest,
    nonTriggeringExamples: [
      Example("let x = 1_000_000"),
      Example("let x = 100"),
      Example("let x = 0xFF"),
      Example("let x = 1_000"),
    ],
    triggeringExamples: [
      Example("let x = ↓1000000"),
      Example("let x = ↓100000"),
    ],
  )
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
      guard !literal.hasPrefix("0x"), !literal.hasPrefix("0b"), !literal.hasPrefix("0o") else {
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
