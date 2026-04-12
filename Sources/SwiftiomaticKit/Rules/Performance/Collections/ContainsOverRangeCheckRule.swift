import SwiftiomaticSyntax

struct ContainsOverRangeCheckRule {
  static let id = "contains_over_range_check"
  static let name = "Contains Over Range Check"
  static let summary = "Prefer `contains` over `range(of:) != nil` and `range(of:) == nil`"
  static let isOptIn = true
  static var nonTriggeringExamples: [Example] {
    [
      Example("let range = myString.range(of: \"Test\")"),
      Example("myString.contains(\"Test\")"),
      Example("!myString.contains(\"Test\")"),
      Example("resourceString.range(of: rule.regex, options: .regularExpression) != nil"),
    ]
  }

  static var triggeringExamples: [Example] {
    ["!=", "=="].flatMap { comparison in
      [
        Example("↓myString.range(of: \"Test\") \(comparison) nil")
      ]
    }
  }

  var options = SeverityOption<Self>(.warning)
}

extension ContainsOverRangeCheckRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ContainsOverRangeCheckRule {
  func preprocess(file: SwiftSource) -> SourceFileSyntax? {
    file.foldedSyntaxTree
  }
}

extension ContainsOverRangeCheckRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: InfixOperatorExprSyntax) {
      guard
        let operatorNode = node.operator.as(BinaryOperatorExprSyntax.self),
        operatorNode.operator.tokenKind.isEqualityComparison,
        node.rightOperand.is(NilLiteralExprSyntax.self),
        let first = node.leftOperand.asFunctionCall,
        first.arguments.onlyElement?.label?.text == "of",
        let calledExpression = first.calledExpression.as(MemberAccessExprSyntax.self),
        calledExpression.declName.baseName.text == "range"
      else {
        return
      }

      violations.append(first.positionAfterSkippingLeadingTrivia)
    }
  }
}
