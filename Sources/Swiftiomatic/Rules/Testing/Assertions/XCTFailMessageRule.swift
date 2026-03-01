import SwiftSyntax

struct XCTFailMessageRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = XCTFailMessageConfiguration()

  static let description = RuleDescription(
    identifier: "xctfail_message",
    name: "XCTFail Message",
    description: "An XCTFail call should include a description of the assertion",
    nonTriggeringExamples: [
      Example(
        """
        func testFoo() {
          XCTFail("bar")
        }
        """,
      ),
      Example(
        """
        func testFoo() {
          XCTFail(bar)
        }
        """,
      ),
    ],
    triggeringExamples: [
      Example(
        """
        func testFoo() {
          ↓XCTFail()
        }
        """,
      ),
      Example(
        """
        func testFoo() {
          ↓XCTFail("")
        }
        """,
      ),
    ],
  )
}

extension XCTFailMessageRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension XCTFailMessageRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      guard
        let expression = node.calledExpression.as(DeclReferenceExprSyntax.self),
        expression.baseName.text == "XCTFail",
        node.arguments.isEmptyOrEmptyString
      else {
        return
      }

      violations.append(node.positionAfterSkippingLeadingTrivia)
    }
  }
}

extension LabeledExprListSyntax {
  fileprivate var isEmptyOrEmptyString: Bool {
    if isEmpty {
      return true
    }
    return count == 1
      && first?.expression.as(StringLiteralExprSyntax.self)?
        .isEmptyString == true
  }
}
