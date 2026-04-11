import SwiftSyntax

struct XCTFailMessageRule {
  static let id = "xctfail_message"
  static let name = "XCTFail Message"
  static let summary = "An XCTFail call should include a description of the assertion"
  static var nonTriggeringExamples: [Example] {
    [
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
    ]
  }

  static var triggeringExamples: [Example] {
    [
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
    ]
  }

  var options = SeverityOption<Self>(.warning)
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
