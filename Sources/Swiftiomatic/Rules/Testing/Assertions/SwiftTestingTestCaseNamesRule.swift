import Foundation
import SwiftSyntax

struct SwiftTestingTestCaseNamesRule {
    static let id = "swift_testing_test_case_names"
    static let name = "Swift Testing Test Case Names"
    static let summary = "In Swift Testing, `@Test` methods should not have a `test` prefix"
    static let scope: Scope = .suggest
    static var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                @Test func myFeatureWorks() {}
                """),
              Example(
                """
                func testSomething() {}
                """),
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example(
                """
                @Test func ↓testMyFeatureWorks() {}
                """),
            ]
    }
  var options = SeverityOption<Self>(.warning)

}

extension SwiftTestingTestCaseNamesRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
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
