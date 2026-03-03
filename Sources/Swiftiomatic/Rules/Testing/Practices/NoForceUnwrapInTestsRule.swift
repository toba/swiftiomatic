import SwiftSyntax

struct NoForceUnwrapInTestsRule {
  static let id = "no_force_unwrap_in_tests"
  static let name = "No Force Unwrap in Tests"
  static let summary = "Use `XCTUnwrap` or `#require` instead of force unwrapping in test methods"
  static let isOptIn = true
  static var nonTriggeringExamples: [Example] {
    [
      Example(
        """
        class FooTests: XCTestCase {
          func test_example() throws {
            let value = try XCTUnwrap(optional)
          }
        }
        """
      ),
      Example(
        """
        class FooTests: XCTestCase {
          func notATest() {
            let value = optional!
          }
        }
        """
      ),
      Example("let value = optional!"),
      Example(
        """
        class FooTests: XCTestCase {
          func test_example() {
            let value: String! = "hello"
          }
        }
        """
      ),
    ]
  }
  static var triggeringExamples: [Example] {
    [
      Example(
        """
        class FooTests: XCTestCase {
          func test_example() {
            let value = ↓optional!
          }
        }
        """
      ),
      Example(
        """
        class FooTests: XCTestCase {
          func test_example() {
            ↓foo!.bar()
          }
        }
        """
      ),
    ]
  }
  var options = SeverityOption<Self>(.warning)
}

extension NoForceUnwrapInTestsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension NoForceUnwrapInTestsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    private var insideTestMethod = false

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
      guard node.inheritanceClause.containsInheritedType(
        inheritedTypes: ["XCTestCase", "QuickSpec"]
      ) else {
        return .skipChildren
      }
      return .visitChildren
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
      if node.isDiscoverableTestMethod {
        insideTestMethod = true
      }
      return .visitChildren
    }

    override func visitPost(_: FunctionDeclSyntax) {
      insideTestMethod = false
    }

    override func visitPost(_ node: ForceUnwrapExprSyntax) {
      guard insideTestMethod else { return }
      violations.append(node.expression.positionAfterSkippingLeadingTrivia)
    }
  }
}
