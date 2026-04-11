import SwiftSyntax

struct NoForceTryInTestsRule {
  static let id = "no_force_try_in_tests"
  static let name = "No Force Try in Tests"
  static let summary = "Prefer `throws` test functions over `try!` in test methods"
  static let isOptIn = true
  static let deprecatedAliases: Set<String> = ["throwing_tests"]
  static var nonTriggeringExamples: [Example] {
    [
      Example(
        """
        class FooTests: XCTestCase {
          func test_example() throws {
            try doSomething()
          }
        }
        """,
      ),
      Example(
        """
        class FooTests: XCTestCase {
          func notATest() {
            try! doSomething()
          }
        }
        """,
      ),
      Example("try! doSomething()"),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(
        """
        class FooTests: XCTestCase {
          func test_example() {
            ↓try! doSomething()
          }
        }
        """,
      ),
      Example(
        """
        class FooTests: XCTestCase {
          func test_example() {
            let x = ↓try! getValue()
          }
        }
        """,
      ),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension NoForceTryInTestsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension NoForceTryInTestsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    /// Track whether we're inside a test method
    private var insideTestMethod = false

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
      // Only visit test classes
      guard
        node.inheritanceClause.containsInheritedType(
          inheritedTypes: ["XCTestCase", "QuickSpec"],
        )
      else {
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

    override func visitPost(_ node: TryExprSyntax) {
      guard insideTestMethod,
        node.questionOrExclamationMark?.tokenKind == .exclamationMark
      else {
        return
      }
      violations.append(node.tryKeyword.positionAfterSkippingLeadingTrivia)
    }
  }
}
