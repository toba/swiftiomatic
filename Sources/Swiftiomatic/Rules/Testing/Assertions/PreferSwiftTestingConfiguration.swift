struct PreferSwiftTestingConfiguration: RuleConfiguration {
    let id = "prefer_swift_testing"
    let name = "Prefer Swift Testing"
    let summary = "XCTest-based test suites can be migrated to the Swift Testing framework"
    let scope: Scope = .suggest
    var nonTriggeringExamples: [Example] {
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
    var triggeringExamples: [Example] {
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
}
