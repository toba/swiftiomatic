@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoForceTryInTestsTests: RuleTesting {

  // MARK: - Swift Testing

  @Test func swiftTestingForceTryReplaced() {
    assertFormatting(
      NoForceTryInTests.self,
      input: """
        import Testing

        @Test func something() {
            1️⃣try! somethingThatThrows()
        }
        """,
      expected: """
        import Testing

        @Test func something() throws {
            try somethingThatThrows()
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'try!' with 'try' in test function; use 'throws' on the test method instead"),
      ]
    )
  }

  @Test func nonTestFunctionNotChanged() {
    assertFormatting(
      NoForceTryInTests.self,
      input: """
        import Testing

        func something() {
            try! somethingThatThrows()
        }

        func test_something() {
            try! somethingThatThrows()
        }
        """,
      expected: """
        import Testing

        func something() {
            try! somethingThatThrows()
        }

        func test_something() {
            try! somethingThatThrows()
        }
        """,
      findings: []
    )
  }

  @Test func asyncTestUpdated() {
    assertFormatting(
      NoForceTryInTests.self,
      input: """
        import Testing

        @Test func something() async {
            1️⃣try! await somethingThatThrows()
        }
        """,
      expected: """
        import Testing

        @Test func something() async throws {
            try await somethingThatThrows()
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'try!' with 'try' in test function; use 'throws' on the test method instead"),
      ]
    )
  }

  @Test func alreadyThrowsUpdated() {
    assertFormatting(
      NoForceTryInTests.self,
      input: """
        import Testing

        @Test func something() throws {
            1️⃣try! somethingThatThrows()
        }
        """,
      expected: """
        import Testing

        @Test func something() throws {
            try somethingThatThrows()
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'try!' with 'try' in test function; use 'throws' on the test method instead"),
      ]
    )
  }

  @Test func multipleForceTrysReplaced() {
    assertFormatting(
      NoForceTryInTests.self,
      input: """
        import Testing

        @Test func something() {
            1️⃣try! somethingThatThrows()
            2️⃣try! somethingThatThrows()
        }
        """,
      expected: """
        import Testing

        @Test func something() throws {
            try somethingThatThrows()
            try somethingThatThrows()
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'try!' with 'try' in test function; use 'throws' on the test method instead"),
        FindingSpec("2️⃣", message: "replace 'try!' with 'try' in test function; use 'throws' on the test method instead"),
      ]
    )
  }

  @Test func forceTryInClosureNotChanged() {
    assertFormatting(
      NoForceTryInTests.self,
      input: """
        import Testing

        @Test func something() {
            someFunction {
                try! somethingThatThrows()
            }
        }
        """,
      expected: """
        import Testing

        @Test func something() {
            someFunction {
                try! somethingThatThrows()
            }
        }
        """,
      findings: []
    )
  }

  @Test func forceTryInIfStatementReplaced() {
    assertFormatting(
      NoForceTryInTests.self,
      input: """
        import Testing

        @Test func something() {
            if condition {
                1️⃣try! somethingThatThrows()
            }
        }
        """,
      expected: """
        import Testing

        @Test func something() throws {
            if condition {
                try somethingThatThrows()
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'try!' with 'try' in test function; use 'throws' on the test method instead"),
      ]
    )
  }

  @Test func forceTryInClosureInsideIfNotChanged() {
    assertFormatting(
      NoForceTryInTests.self,
      input: """
        import Testing

        @Test func something() {
            doSomething {
                if condition {
                    try! somethingThatThrows()
                }
            }
        }
        """,
      expected: """
        import Testing

        @Test func something() {
            doSomething {
                if condition {
                    try! somethingThatThrows()
                }
            }
        }
        """,
      findings: []
    )
  }

  @Test func forceTryInNestedFunctionNotChanged() {
    assertFormatting(
      NoForceTryInTests.self,
      input: """
        import Testing

        @Test func something() {
            func nestedFunction() {
                if condition {
                    try! somethingThatThrows()
                }
            }
        }
        """,
      expected: """
        import Testing

        @Test func something() {
            func nestedFunction() {
                if condition {
                    try! somethingThatThrows()
                }
            }
        }
        """,
      findings: []
    )
  }

  // MARK: - XCTest

  @Test func xcTestForceTryReplaced() {
    assertFormatting(
      NoForceTryInTests.self,
      input: """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                1️⃣try! somethingThatThrows()
            }
        }
        """,
      expected: """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                try somethingThatThrows()
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'try!' with 'try' in test function; use 'throws' on the test method instead"),
      ]
    )
  }

  @Test func xcTestHelperNotChanged() {
    assertFormatting(
      NoForceTryInTests.self,
      input: """
        import XCTest

        class TestCase: XCTestCase {
            func testHelper(arg: Bool) {
                try! somethingThatThrows(with: arg)
            }
        }
        """,
      expected: """
        import XCTest

        class TestCase: XCTestCase {
            func testHelper(arg: Bool) {
                try! somethingThatThrows(with: arg)
            }
        }
        """,
      findings: []
    )
  }

  @Test func xcTestNonTestMethodNotChanged() {
    assertFormatting(
      NoForceTryInTests.self,
      input: """
        import XCTest

        class TestCase: XCTestCase {
            func something() {
                try! somethingThatThrows()
            }

            func testHelper() -> String {
                try! generateString()
            }
        }
        """,
      expected: """
        import XCTest

        class TestCase: XCTestCase {
            func something() {
                try! somethingThatThrows()
            }

            func testHelper() -> String {
                try! generateString()
            }
        }
        """,
      findings: []
    )
  }
}
