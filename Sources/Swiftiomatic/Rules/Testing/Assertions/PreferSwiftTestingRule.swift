import SwiftSyntax

struct PreferSwiftTestingRule: Rule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "prefer_swift_testing",
    name: "Prefer Swift Testing",
    description: "XCTest-based test suites can be migrated to the Swift Testing framework",
    scope: .suggest,
    minSwiftVersion: .v6,
    nonTriggeringExamples: [
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
    ],
    triggeringExamples: [
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
    ],
  )
}

extension PreferSwiftTestingRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<ConfigurationType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension PreferSwiftTestingRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<ConfigurationType> {
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
