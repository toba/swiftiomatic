import SwiftSyntax

struct ReduceBooleanRule {
    static let id = "reduce_boolean"
    static let name = "Reduce Boolean"
    static let summary = "Prefer using `.allSatisfy()` or `.contains()` over `reduce(true)` or `reduce(false)`."
    static var nonTriggeringExamples: [Example] {
        [
              Example("nums.reduce(0) { $0.0 + $0.1 }"),
              Example("nums.reduce(0.0) { $0.0 + $0.1 }"),
              Example("nums.reduce(initial: true) { $0.0 && $0.1 == 3 }"),
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example("let allNines = nums.↓reduce(true) { $0.0 && $0.1 == 9 }"),
              Example("let anyNines = nums.↓reduce(false) { $0.0 || $0.1 == 9 }"),
              Example("let allValid = validators.↓reduce(true) { $0 && $1(input) }"),
              Example("let anyValid = validators.↓reduce(false) { $0 || $1(input) }"),
              Example("let allNines = nums.↓reduce(true, { $0.0 && $0.1 == 9 })"),
              Example("let anyNines = nums.↓reduce(false, { $0.0 || $0.1 == 9 })"),
              Example("let allValid = validators.↓reduce(true, { $0 && $1(input) })"),
              Example("let anyValid = validators.↓reduce(false, { $0 || $1(input) })"),
              Example("nums.reduce(into: true) { (r: inout Bool, s) in r = r && (s == 3) }"),
            ]
    }
  var options = SeverityConfiguration<Self>(.warning)

}

extension ReduceBooleanRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ReduceBooleanRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      guard
        let calledExpression = node.calledExpression.as(MemberAccessExprSyntax.self),
        calledExpression.declName.baseName.text == "reduce",
        let firstArgument = node.arguments.first,
        firstArgument.label?.text ?? "into" == "into",
        let bool = firstArgument.expression.as(BooleanLiteralExprSyntax.self)
      else {
        return
      }

      let suggestedFunction = bool.literal.tokenKind == .keyword(.true) ? "allSatisfy" : "contains"
      violations.append(
        SyntaxViolation(
          position: calledExpression.declName.baseName.positionAfterSkippingLeadingTrivia,
          reason: "Use `\(suggestedFunction)` instead",
        ),
      )
    }
  }
}
