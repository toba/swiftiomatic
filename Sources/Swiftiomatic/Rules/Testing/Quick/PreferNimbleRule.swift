import SwiftSyntax

struct PreferNimbleRule: Rule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "prefer_nimble",
    name: "Prefer Nimble",
    description: "Prefer Nimble matchers over XCTAssert functions",
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
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<ConfigurationType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension PreferNimbleRule: OptInRule {}

extension PreferNimbleRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<ConfigurationType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      if let expr = node.calledExpression.as(DeclReferenceExprSyntax.self),
        expr.baseName.text.starts(with: "XCTAssert")
      {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
