import SwiftSyntax

struct PreferNimbleRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "prefer_nimble",
    name: "Prefer Nimble",
    description: "Prefer Nimble matchers over XCTAssert functions",
    isOptIn: true,
    nonTriggeringExamples: [
      Example("expect(foo) == 1"),
      Example("expect(foo).to(equal(1))"),
    ],
    triggeringExamples: [
      Example("↓XCTAssertTrue(foo)"),
      Example("↓XCTAssertEqual(foo, 2)"),
      Example("↓XCTAssertNotEqual(foo, 2)"),
      Example("↓XCTAssertNil(foo)"),
      Example("↓XCTAssert(foo)"),
      Example("↓XCTAssertGreaterThan(foo, 10)"),
    ],
  )
}

extension PreferNimbleRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension PreferNimbleRule {}

extension PreferNimbleRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      if let expr = node.calledExpression.as(DeclReferenceExprSyntax.self),
        expr.baseName.text.starts(with: "XCTAssert")
      {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
