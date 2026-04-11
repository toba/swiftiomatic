import SwiftSyntax

struct PreferNimbleRule {
  static let id = "prefer_nimble"
  static let name = "Prefer Nimble"
  static let summary = "Prefer Nimble matchers over XCTAssert functions"
  static let isOptIn = true
  static var nonTriggeringExamples: [Example] {
    [
      Example("expect(foo) == 1"),
      Example("expect(foo).to(equal(1))"),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("↓XCTAssertTrue(foo)"),
      Example("↓XCTAssertEqual(foo, 2)"),
      Example("↓XCTAssertNotEqual(foo, 2)"),
      Example("↓XCTAssertNil(foo)"),
      Example("↓XCTAssert(foo)"),
      Example("↓XCTAssertGreaterThan(foo, 10)"),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension PreferNimbleRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

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
