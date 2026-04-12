import SwiftiomaticSyntax

struct ValidateTestCasesRule {
  static let id = "validate_test_cases"
  static let name = "Validate Test Cases"
  static let summary =
    "Test methods in XCTestCase subclasses should start with `test`"
  static let isOptIn = true
  static var nonTriggeringExamples: [Example] {
    [
      Example(
        """
        class FooTests: XCTestCase {
          func testExample() {
            XCTAssertTrue(true)
          }
        }
        """,
      ),
      Example(
        """
        class FooTests: XCTestCase {
          private func helperMethod() {}
        }
        """,
      ),
      Example(
        """
        class FooTests: XCTestCase {
          override func setUp() {}
        }
        """,
      ),
      Example(
        """
        class FooTests: XCTestCase {
          func testExample() {
            XCTAssertTrue(true)
          }
          private func helperWithXCTAssert() {
            XCTAssertTrue(true)
          }
        }
        """,
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(
        """
        class FooTests: XCTestCase {
          func ↓example() {
            XCTAssertTrue(true)
          }
        }
        """,
      ),
      Example(
        """
        class FooTests: XCTestCase {
          func ↓shouldDoSomething() {
            XCTAssertEqual(a, b)
          }
        }
        """,
      ),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension ValidateTestCasesRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

private let xctAssertFunctions: Set<String> = [
  "XCTAssert", "XCTAssertTrue", "XCTAssertFalse",
  "XCTAssertEqual", "XCTAssertNotEqual",
  "XCTAssertNil", "XCTAssertNotNil",
  "XCTAssertGreaterThan", "XCTAssertGreaterThanOrEqual",
  "XCTAssertLessThan", "XCTAssertLessThanOrEqual",
  "XCTAssertThrowsError", "XCTAssertNoThrow",
  "XCTAssertIdentical", "XCTAssertNotIdentical",
  "XCTFail", "XCTUnwrap",
]

extension ValidateTestCasesRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    private var inTestClass = false

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
      if node.inheritanceClause.containsInheritedType(inheritedTypes: ["XCTestCase"]) {
        inTestClass = true
        return .visitChildren
      }
      return .skipChildren
    }

    override func visitPost(_: ClassDeclSyntax) {
      inTestClass = false
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
      guard inTestClass else { return }

      let name = node.name.text

      // Skip if already prefixed with test
      guard !name.hasPrefix("test") else { return }

      // Skip lifecycle methods
      guard !["setUp", "setUpWithError", "tearDown", "tearDownWithError"].contains(name)
      else {
        return
      }

      // Skip private/fileprivate methods — these are helpers
      if node.modifiers.contains(keyword: .private)
        || node.modifiers.contains(keyword: .fileprivate)
      {
        return
      }

      // Skip overrides
      if node.modifiers.contains(keyword: .override) {
        return
      }

      // Skip static/class methods
      if node.modifiers.contains(keyword: .static)
        || node.modifiers
          .contains(keyword: .class)
      {
        return
      }

      // Check if the function body contains XCTest assertions
      guard let body = node.body, containsXCTAssert(body) else {
        return
      }

      violations.append(
        SyntaxViolation(
          position: node.name.positionAfterSkippingLeadingTrivia,
          reason: "Test method '\(name)' should start with 'test' prefix",
        ),
      )
    }

    private func containsXCTAssert(_ body: CodeBlockSyntax) -> Bool {
      for statement in body.statements {
        if containsXCTAssertCall(Syntax(statement)) {
          return true
        }
      }
      return false
    }

    private func containsXCTAssertCall(_ node: Syntax) -> Bool {
      if let call = node.as(FunctionCallExprSyntax.self),
        let callee = call.calledExpression.as(DeclReferenceExprSyntax.self),
        xctAssertFunctions.contains(callee.baseName.text)
      {
        return true
      }
      for child in node.children(viewMode: .sourceAccurate) {
        if containsXCTAssertCall(child) {
          return true
        }
      }
      return false
    }
  }
}
