@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoForceTryTests: RuleTesting {

  // MARK: - Non-test code: diagnose only

  @Test func invalidTryExpression() {
    assertFormatting(
      NoForceTry.self,
      input: """
        let document = 1️⃣try! Document(path: "important.data")
        let document = try Document(path: "important.data")
        let x = 2️⃣try! someThrowingFunction()
        let x = try? someThrowingFunction(
          3️⃣try! someThrowingFunction()
        )
        let x = try someThrowingFunction(
          4️⃣try! someThrowingFunction()
        )
        if let data = try? fetchDataFromDisk() { return data }
        """,
      expected: """
        let document = try! Document(path: "important.data")
        let document = try Document(path: "important.data")
        let x = try! someThrowingFunction()
        let x = try? someThrowingFunction(
          try! someThrowingFunction()
        )
        let x = try someThrowingFunction(
          try! someThrowingFunction()
        )
        if let data = try? fetchDataFromDisk() { return data }
        """,
      findings: [
        FindingSpec("1️⃣", message: "do not use force try"),
        FindingSpec("2️⃣", message: "do not use force try"),
        FindingSpec("3️⃣", message: "do not use force try"),
        FindingSpec("4️⃣", message: "do not use force try"),
      ]
    )
  }

  @Test func allowForceTryInTestCode() {
    assertFormatting(
      NoForceTry.self,
      input: """
        import XCTest

        class TestCase: XCTestCase {
            func something() {
                let document = try! Document(path: "important.data")
            }
        }
        """,
      expected: """
        import XCTest

        class TestCase: XCTestCase {
            func something() {
                let document = try! Document(path: "important.data")
            }
        }
        """,
      findings: []
    )
  }

  @Test func allowForceTryInTestAttributeFunction() {
    assertFormatting(
      NoForceTry.self,
      input: """
        import Testing

        @Test func someFunc() {
          let document = 1️⃣try! Document(path: "important.data")
          func nestedFunc() {
            let x = try! someThrowingFunction()
          }
        }
        """,
      expected: """
        import Testing

        @Test func someFunc() throws {
          let document = try Document(path: "important.data")
          func nestedFunc() {
            let x = try! someThrowingFunction()
          }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'try!' with 'try' in test function; use 'throws' on the test method instead"),
      ]
    )
  }

  // MARK: - Swift Testing: auto-fix

  @Test func swiftTestingForceTryReplaced() {
    assertFormatting(
      NoForceTry.self,
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
      NoForceTry.self,
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
      NoForceTry.self,
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
      NoForceTry.self,
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
      NoForceTry.self,
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
      NoForceTry.self,
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
      NoForceTry.self,
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
      NoForceTry.self,
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
      NoForceTry.self,
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

  // MARK: - XCTest: auto-fix

  @Test func xcTestForceTryReplaced() {
    assertFormatting(
      NoForceTry.self,
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
      NoForceTry.self,
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
      NoForceTry.self,
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
