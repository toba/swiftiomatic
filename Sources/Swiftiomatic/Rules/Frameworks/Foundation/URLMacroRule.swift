import SwiftSyntax

struct URLMacroRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "url_macro",
    name: "URL Macro",
    description: "Force-unwrapped `URL(string:)` can be replaced with a `#URL` macro",
    scope: .suggest,
    nonTriggeringExamples: [
      Example("let url = URL(string: variable)"),
      Example("let url = URL(string: \"https://example.com\")"),
    ],
    triggeringExamples: [
      Example("let url = ↓URL(string: \"https://example.com\")!"),
    ],
  )
}

extension URLMacroRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension URLMacroRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: ForceUnwrapExprSyntax) {
      // Check if the unwrapped expression is URL(string: "...")
      guard let call = node.expression.as(FunctionCallExprSyntax.self),
        let callee = call.calledExpression.as(DeclReferenceExprSyntax.self),
        callee.baseName.text == "URL"
      else { return }

      // Check for single argument labeled "string"
      let args = call.arguments
      guard args.count == 1,
        let firstArg = args.first,
        firstArg.label?.text == "string"
      else { return }

      // Check if the argument is a string literal (no interpolation)
      guard firstArg.expression.is(StringLiteralExprSyntax.self) else { return }

      violations.append(callee.baseName.positionAfterSkippingLeadingTrivia)
    }
  }
}
