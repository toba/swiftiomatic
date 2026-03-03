import SwiftSyntax

struct NoGuardInTestsRule {
  static let id = "no_guard_in_tests"
  static let name = "No Guard in Tests"
  static let summary = "Prefer `#require` or `XCTUnwrap` over `guard` in test methods"
  static let isOptIn = true
  static var nonTriggeringExamples: [Example] {
    [
      Example(
        """
        class FooTests: XCTestCase {
          func test_example() throws {
            let value = try #require(optional)
          }
        }
        """
      ),
      Example(
        """
        class FooTests: XCTestCase {
          func notATest() {
            guard let value = optional else { return }
          }
        }
        """
      ),
      Example(
        """
        func notInTestClass() {
          guard let value = optional else { return }
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
            ↓guard let value = optional else { return }
            print(value)
          }
        }
        """
      ),
      Example(
        """
        class FooTests: XCTestCase {
          func test_example() {
            ↓guard condition else { return }
          }
        }
        """
      ),
    ]
  }
  var options = SeverityOption<Self>(.warning)
}

extension NoGuardInTestsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension NoGuardInTestsRule {
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

    override func visitPost(_ node: GuardStmtSyntax) {
      guard insideTestMethod else { return }
      violations.append(node.guardKeyword.positionAfterSkippingLeadingTrivia)
    }
  }
}
