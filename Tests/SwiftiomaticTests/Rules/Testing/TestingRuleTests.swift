import Testing

@testable import Swiftiomatic

// MARK: - PreferSwiftTestingRule

@Suite(.rulesRegistered)
struct PreferSwiftTestingRuleTests {
  @Test func noViolationForSwiftTesting() async {
    await assertNoViolation(
      PreferSwiftTestingRule.self,
      """
      import Testing
      @Suite struct MyTests {
          @Test func example() { #expect(true) }
      }
      """)
  }

  @Test func detectsXCTestCase() async {
    await assertViolates(
      PreferSwiftTestingRule.self,
      """
      import XCTest
      class MyTests: XCTestCase {
          func testExample() { XCTAssertTrue(true) }
      }
      """)
  }
}

// MARK: - SwiftTestingTestCaseNamesRule

@Suite(.rulesRegistered)
struct SwiftTestingTestCaseNamesRuleTests {
  @Test func noViolationForCleanName() async {
    await assertNoViolation(
      SwiftTestingTestCaseNamesRule.self,
      "@Test func myFeatureWorks() {}")
  }

  @Test func detectsTestPrefix() async {
    await assertViolates(
      SwiftTestingTestCaseNamesRule.self,
      "@Test func testMyFeatureWorks() {}")
  }
}
