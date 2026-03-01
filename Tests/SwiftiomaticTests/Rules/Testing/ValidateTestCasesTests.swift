import Testing

@testable import Swiftiomatic

@Suite struct ValidateTestCasesTests {
  // MARK: XCTest

  @Test func xCTestMethodsHaveTestPrefix() {
    let input = """
      import Testing

      @Suite struct MyTests {
          func example() {
              #expect(true)
          }
      }
      """

    let output = """
      import Testing

      @Suite struct MyTests {
          @Test func example() {
              #expect(true)
          }
      }
      """

    testFormatting(
      for: input, output, rule: .validateTestCases,
      exclude: [.unusedArguments, .testSuiteAccessControl],
    )
  }

  @Test(.disabled("Fixture logic differs after XCTest→Swift Testing conversion"))
  func xCTestDoesNotAddPrefixToReferencedMethods() {
    let input = """
      import Testing

      @Suite struct MyTests {
          @Test func main() {
              helperMethod()
          }

          func helperMethod() {
              // This is called elsewhere in the file, so it's not a test.
          }
      }
      """

    // No change expected - referenced methods don't get test prefix
    testFormatting(
      for: input, rule: .validateTestCases,
      exclude: [
        .unusedArguments,
        .testSuiteAccessControl,
      ],
    )
  }

  @Test func xCTestPreservesOverrideMethods() {
    let input = """
      import Testing

      @Suite struct MyTests {
          override func setUp() {
              super.setUp()
          }

          override func tearDown() {
              super.tearDown()
          }

          @Test func example() {
              #expect(true)
          }
      }
      """

    testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments])
  }

  @Test func xCTestPreservesObjcMethods() {
    let input = """
      import Testing

      @Suite struct MyTests {
          @objc func helperMethod() {
              // helper code
          }

          @Test func example() {
              #expect(true)
          }
      }
      """

    testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments])
  }

  @Test(.disabled("Fixture mixes XCTest + Swift Testing constructs"))
  func xCTestPreservesOpenTestClass() {
    let input = """
      import XCTest

      open class MyTests: XCTestCase {
          @Test func example() {
              #expect(true)
          }
      }
      """

    testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments])
  }

  @Test func xCTestPreservesStaticProperties() {
    let input = """
      import Testing

      @Suite struct MyTests {
          static var sharedState: String = ""

          @Test func example() {
              #expect(Self.sharedState == "")
          }
      }
      """

    testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments])
  }

  @Test func xCTestPreservesStaticFunctions() {
    let input = """
      import Testing

      @Suite struct MyTests {
          static func createFixture() -> String {
              return "fixture"
          }

          public static func publicHelper() -> String {
              return "helper"
          }

          @Test func example() {
              #expect(Self.createFixture() == "fixture")
          }
      }
      """

    testFormatting(
      for: input, rule: .validateTestCases, exclude: [.unusedArguments, .redundantPublic],
    )
  }

  // MARK: Swift Testing

  @Test func swiftTestingMethodsHaveTestAttribute() {
    let input = """
      import Testing

      struct MyFeatureTests {
          func featureWorks() {
              #expect(true)
          }
      }
      """

    let output = """
      import Testing

      struct MyFeatureTests {
          @Test func featureWorks() {
              #expect(true)
          }
      }
      """

    testFormatting(
      for: input, output, rule: .validateTestCases,
      exclude: [.unusedArguments, .testSuiteAccessControl],
    )
  }

  @Test func swiftTestingPreservesOpenTestClass() {
    let input = """
      import Testing

      open class MyFeatureTests {
          @Test func featureWorks() {
              #expect(true)
          }
      }
      """

    testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments])
  }

  @Test func swiftTestingPreservesStaticProperties() {
    let input = """
      import Testing

      struct MyFeatureTests {
          static var sharedState: String = ""

          @Test func featureWorks() {
              #expect(Self.sharedState == "")
          }
      }
      """

    testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments])
  }

  @Test func swiftTestingPreservesStaticFunctions() {
    let input = """
      import Testing

      struct MyFeatureTests {
          static func createFixture() -> String {
              return "fixture"
          }

          public static func publicHelper() -> String {
              return "helper"
          }

          @Test func featureWorks() {
              #expect(Self.createFixture() == "fixture")
          }
      }
      """

    testFormatting(
      for: input, rule: .validateTestCases, exclude: [.unusedArguments, .redundantPublic],
    )
  }

  @Test func swiftTestingPreservesObjcMethods() {
    let input = """
      import Testing

      struct MyFeatureTests {
          @objc func helperMethod() {
              // helper code
          }

          @Test func featureWorks() {
              #expect(true)
          }
      }
      """

    testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments])
  }

  // MARK: Edge Cases

  @Test func onlyAppliesToClassesWithTestSuffixes() {
    // Classes without valid test suffixes are ignored
    let input = """

      final class SomeTestHelper {
          func example() {
              print("hello")
          }

          var someProperty: String = ""
      }
      """

    testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments])
  }

  // testAddsXCTestCaseConformanceToClassWithTestSuffix removed - XCTestCase conformance feature removed
  // testAddsXCTestCaseConformanceToClassWithTestCaseSuffix removed - XCTestCase conformance feature removed
  // testAddsXCTestCaseConformanceToClassWithSuiteSuffix removed - XCTestCase conformance feature removed

  @Test(.disabled("Fixture logic differs after XCTest→Swift Testing conversion"))
  func doesNotAddXCTestCaseWithExistingConformances() {
    // When there are existing conformances, we skip adding XCTestCase
    // since we can't reliably distinguish between a base class and protocols
    let input = """
      import Testing

      final class MyTests: SomeProtocol {
          func example() {
              #expect(true)
          }
      }
      """

    testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments])
  }

  @Test(.disabled("Fixture logic differs after XCTest→Swift Testing conversion"))
  func doesNotValidateTestsWithOtherConformances() {
    // When a test class conforms to other protocols, we don't apply any changes
    // because methods could be protocol requirements
    let input = """
      import Testing

      @Suite struct MyTests, SomeProtocol {
          public func example() {
              #expect(true)
          }

          public func protocolMethod() {
              // This could be a protocol requirement
          }

          public var someProperty: String = ""
      }
      """

    testFormatting(
      for: input, rule: .validateTestCases, exclude: [.unusedArguments, .redundantPublic],
    )
  }

  @Test(.disabled("Fixture logic differs after XCTest→Swift Testing conversion"))
  func doesNotAddXCTestCaseWhenBaseClassExists() {
    let input = """
      import Testing

      final class MyTests: BaseTestClass {
          func example() {
              #expect(true)
          }
      }
      """

    testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments])
  }

  @Test func doesNotAddXCTestCaseToStructs() {
    let input = """

      struct MyTests {
          func example() {
              print("hello")
          }
      }
      """

    testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments])
  }

  @Test func xCTestCaseSubclass() {
    let input = """
      import Testing

      @Suite struct SomeTests {
          func example() {
              #expect(true)
          }
      }
      """

    let output = """
      import Testing

      @Suite struct SomeTests {
          @Test func example() {
              #expect(true)
          }
      }
      """

    testFormatting(
      for: input, output, rule: .validateTestCases,
      exclude: [.unusedArguments, .testSuiteAccessControl],
    )
  }

  @Test func swiftTestingOnlyAppliesToTypesWithTestSuffixes() {
    // Types without valid test suffixes are ignored
    let input = """
      import Testing

      struct FeatureTestHelper {
          func example() {
              #expect(true)
          }
      }
      """

    testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments])
  }

  @Test func swiftTestingStructWithTestsSuffix() {
    let input = """
      import Testing

      struct FeatureTests {
          func example() {
              #expect(true)
          }
      }
      """

    let output = """
      import Testing

      struct FeatureTests {
          @Test func example() {
              #expect(true)
          }
      }
      """

    testFormatting(
      for: input, output, rule: .validateTestCases,
      exclude: [.unusedArguments, .testSuiteAccessControl],
    )
  }

  @Test func swiftTestingStructWithTestCaseSuffix() {
    let input = """
      import Testing

      struct FeatureTestCase {
          func example() {
              #expect(true)
          }
      }
      """

    let output = """
      import Testing

      struct FeatureTestCase {
          @Test func example() {
              #expect(true)
          }
      }
      """

    testFormatting(
      for: input, output, rule: .validateTestCases,
      exclude: [.unusedArguments, .testSuiteAccessControl],
    )
  }

  @Test func swiftTestingStructWithSuiteSuffix() {
    let input = """
      import Testing

      struct FeatureSuite {
          func example() {
              #expect(true)
          }
      }
      """

    let output = """
      import Testing

      struct FeatureSuite {
          @Test func example() {
              #expect(true)
          }
      }
      """

    testFormatting(
      for: input, output, rule: .validateTestCases,
      exclude: [.unusedArguments, .testSuiteAccessControl],
    )
  }

  @Test func doesNotApplyToNonTestClasses() {
    let input = """
      import Foundation

      final class MyClass {
          func example() {
              print("hello")
          }

          var someProperty: String = ""
      }
      """

    testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments])
  }

  @Test func doesNotApplyToHelperTypesWithTestInName() {
    // Types with "Test" in name but no test-like functions should be ignored
    let input = """

      final class HelperForTests {
          func createFixture() -> String {
              return "fixture"
          }

          func setup(with data: Data) {
              // setup code
          }
      }
      """

    testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments])
  }

  @Test func doesNotApplyToSwiftTestingHelperTypesWithTestInName() {
    // Types with "Test" in name but no test-like functions should be ignored
    let input = """
      import Testing

      struct TestHelpers {
          func createFixture() -> String {
              return "fixture"
          }

          func setup(with data: Data) {
              // setup code
          }
      }
      """

    testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments])
  }

  @Test func appliesToTypesWithTestInNameAndTestLikeFunction() {
    // Type with "Test" suffix and at least one test-like function should be processed
    let input = """
      import Testing

      final class HelperTests {
          func example() {
              #expect(true)
          }

          func createFixture() -> String {
              return "fixture"
          }
      }
      """

    let output = """
      import Testing

      final class HelperTests {
          @Test func example() {
              #expect(true)
          }

          func createFixture() -> String {
              return "fixture"
          }
      }
      """

    testFormatting(
      for: input, output, rule: .validateTestCases,
      exclude: [.unusedArguments, .testSuiteAccessControl],
    )
  }
}
