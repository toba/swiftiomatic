import SwiftSyntax

struct DiscouragedAssertRule {
    static let id = "discouraged_assert"
    static let name = "Discouraged Assert"
    static let summary = "Prefer `assertionFailure()` and/or `preconditionFailure()` over `assert(false)`"
    static let isOptIn = true
    static var nonTriggeringExamples: [Example] {
        [
              Example(#"assert(true)"#),
              Example(#"assert(true, "foobar")"#),
              Example(#"assert(true, "foobar", file: "toto", line: 42)"#),
              Example(#"assert(false || true)"#),
              Example(#"XCTAssert(false)"#),
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example(#"↓assert(false)"#),
              Example(#"↓assert(false, "foobar")"#),
              Example(#"↓assert(false, "foobar", file: "toto", line: 42)"#),
              Example(#"↓assert(   false    , "foobar")"#),
            ]
    }
  var options = SeverityConfiguration<Self>(.warning)

}

extension DiscouragedAssertRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension DiscouragedAssertRule {}

extension DiscouragedAssertRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      guard node.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text == "assert",
        let firstArg = node.arguments.first,
        firstArg.label == nil,
        let boolExpr = firstArg.expression.as(BooleanLiteralExprSyntax.self),
        boolExpr.literal.tokenKind == .keyword(.false)
      else {
        return
      }

      violations.append(node.positionAfterSkippingLeadingTrivia)
    }
  }
}
