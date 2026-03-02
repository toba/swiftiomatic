import SwiftSyntax

struct PreferSwiftTestingRule {
    static let id = "prefer_swift_testing"
    static let name = "Prefer Swift Testing"
    static let summary = "XCTest-based test suites can be migrated to the Swift Testing framework"
    static let scope: Scope = .suggest
    static var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                import Testing

                @Suite struct MyTests {
                  @Test func example() {
                    #expect(true)
                  }
                }
                """,
              )
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example(
                """
                import XCTest

                ↓class MyTests: XCTestCase {
                  func testExample() {
                    XCTAssertTrue(true)
                  }
                }
                """,
              )
            ]
    }
  var options = SeverityConfiguration<Self>(.warning)

}

extension PreferSwiftTestingRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension PreferSwiftTestingRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: ClassDeclSyntax) {
      // Check if class inherits from XCTestCase
      guard let inheritanceClause = node.inheritanceClause,
        inheritanceClause.inheritedTypes.contains(where: {
          $0.type.trimmedDescription == "XCTestCase"
        })
      else { return }

      violations.append(node.classKeyword.positionAfterSkippingLeadingTrivia)
    }
  }
}
