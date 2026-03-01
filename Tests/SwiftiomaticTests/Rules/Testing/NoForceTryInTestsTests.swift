import Testing

@testable import Swiftiomatic

@Suite struct NoForceTryInTestsTests {
  @Test func caseIsUpdated_for_Testing() {
    let input = """
      import Testing

      @Test func something() {
          try! somethingThatThrows()
      }
      """
    let output = """
      import Testing

      @Test func something() throws {
          try somethingThatThrows()
      }
      """
    testFormatting(for: input, output, rule: .noForceTryInTests)
  }

  @Test func nonTestCaseFunction_IsNotUpdated_for_Testing() {
    let input = """
      import Testing

      func something() {
          try! somethingThatThrows()
      }

      /// Testing test cases must be annotated with @Test, otherwise they are not test cases.
      /// This naming is not good style but we don't want to accidentally apply XCTest logic.
      func test_something() {
          try! somethingThatThrows()
      }
      """
    testFormatting(for: input, rule: .noForceTryInTests)
  }

  @Test func caseIsUpdated_for_XCTest() {
    let input = """
      import XCTest

      class TestCase: XCTestCase {
          func test_something() {
              try! somethingThatThrows()
          }
      }
      """
    let output = """
      import XCTest

      class TestCase: XCTestCase {
          func test_something() throws {
              try somethingThatThrows()
          }
      }
      """
    testFormatting(for: input, output, rule: .noForceTryInTests)
  }

  @Test func helperIsNotUpdated_for_XCTest() {
    let input = """
      import XCTest

      class TestCase: XCTestCase {
          func testHelper(arg: Bool) {
              try! somethingThatThrows(with: arg)
          }
      }
      """
    testFormatting(for: input, rule: .noForceTryInTests, exclude: [.testSuiteAccessControl])
  }

  @Test func nonTestCaseFunction_IsNotUpdated_for_XCTest() {
    let input = """
      import XCTest

      class TestCase: XCTestCase {
          func something() {
              try! somethingThatThrows()
          }

          func testHelper() -> String {
              try! generateString()
          }
      }
      """
    testFormatting(
      for: input, rule: .noForceTryInTests,
      exclude: [
        .testSuiteAccessControl,
        .validateTestCases,
      ],
    )
  }

  @Test func caseIsUpdated_for_async_test() {
    let input = """
      import Testing

      @Test func something() async {
          try! await somethingThatThrows()
      }
      """
    let output = """
      import Testing

      @Test func something() async throws {
          try await somethingThatThrows()
      }
      """
    testFormatting(for: input, output, rule: .noForceTryInTests)
  }

  @Test func caseIsUpdated_for_already_throws() {
    let input = """
      import Testing

      @Test func something() throws {
          try! somethingThatThrows()
      }
      """
    let output = """
      import Testing

      @Test func something() throws {
          try somethingThatThrows()
      }
      """
    testFormatting(for: input, output, rule: .noForceTryInTests)
  }

  @Test func caseIsUpdated_for_multiple_try_exclamationMarks() {
    let input = """
      import Testing

      @Test func something() {
          try! somethingThatThrows()
          try! somethingThatThrows()
      }
      """
    let output = """
      import Testing

      @Test func something() throws {
          try somethingThatThrows()
          try somethingThatThrows()
      }
      """
    testFormatting(for: input, output, rule: .noForceTryInTests)
  }

  @Test func caseIsNotUpdated_for_try_exclamationMark_in_closoure() {
    let input = """
      import Testing

      @Test func something() {
          someFunction {
              try! somethingThatThrows()
          }
      }
      """
    testFormatting(for: input, rule: .noForceTryInTests)
  }

  @Test func caseIsUpdated_for_try_exclamationMark_in_if_statement() {
    let input = """
      import Testing

      @Test func something() {
          if condition {
              try! somethingThatThrows()
          }
      }
      """
    let output = """
      import Testing

      @Test func something() throws {
          if condition {
              try somethingThatThrows()
          }
      }
      """
    testFormatting(for: input, output, rule: .noForceTryInTests)
  }

  @Test func caseIsNotUpdated_for_try_exclamationMark_in_closure_inside_if_statement() {
    let input = """
      import Testing

      @Test func something() {
          doSomething {
              if condition {
                  try! somethingThatThrows()
              }
          }
      }
      """
    testFormatting(for: input, rule: .noForceTryInTests)
  }

  @Test func caseIsNotUpdated_for_try_exclamationMark_in_closure_inside_nested_function() {
    let input = """
      import Testing

      @Test func something() {
          func nestedFunction() {
              if condition {
                  try! somethingThatThrows()
              }
          }
      }
      """
    testFormatting(for: input, rule: .noForceTryInTests)
  }
}
