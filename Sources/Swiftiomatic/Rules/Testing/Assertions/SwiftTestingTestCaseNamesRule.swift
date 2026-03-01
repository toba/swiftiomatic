import Foundation
import SwiftSyntax

struct SwiftTestingTestCaseNamesRule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "swift_testing_test_case_names",
    name: "Swift Testing Test Case Names",
    description: "In Swift Testing, `@Test` methods should not have a `test` prefix",
    scope: .suggest,
    nonTriggeringExamples: [
      Example(
        """
        @Test func myFeatureWorks() {}
        """),
      Example(
        """
        func testSomething() {}
        """),
    ],
    triggeringExamples: [
      Example(
        """
        @Test func ↓testMyFeatureWorks() {}
        """),
    ],
  )
}

extension SwiftTestingTestCaseNamesRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension SwiftTestingTestCaseNamesRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionDeclSyntax) {
      // Check if the function has @Test attribute
      let hasTestAttribute = node.attributes.contains {
        if case .attribute(let attr) = $0,
          attr.attributeName.trimmedDescription == "Test"
        {
          return true
        }
        return false
      }
      guard hasTestAttribute else { return }

      // Check if the function name starts with "test"
      let name = node.name.text
      if name.hasPrefix("test"), name.count > 4 {
        violations.append(node.name.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
