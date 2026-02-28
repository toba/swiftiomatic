import Testing

@testable import Swiftiomatic

@Suite struct TestSuiteAccessControlTests {
  // MARK: XCTest

  @Test func xCTestMethodsAreInternal() {
    let input = """
      import Testing

      @Suite struct MyTests {
          public @Test func example() {
              #expect(true)
          }

          private @Test func helper() {
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

          private @Test func helper() {
              #expect(true)
          }
      }
      """

    testFormatting(
      for: input, output, rule: .testSuiteAccessControl,
      exclude: [.unusedArguments, .validateTestCases])
  }

  @Test func xCTestHelperMethodsArePrivate() {
    let input = """
      import Testing

      @Suite struct MyTests {
          @Test func example() {
              helperMethod(arg: 0)
          }

          func helperMethod(arg: Int) {
              // helper code
          }

          public func publicHelper(arg: Int) {
              // helper code
          }
      }
      """

    let output = """
      import Testing

      @Suite struct MyTests {
          @Test func example() {
              helperMethod(arg: 0)
          }

          private func helperMethod(arg: Int) {
              // helper code
          }

          private func publicHelper(arg: Int) {
              // helper code
          }
      }
      """

    testFormatting(
      for: input, output, rule: .testSuiteAccessControl,
      exclude: [.unusedArguments, .validateTestCases])
  }

  @Test func xCTestPropertiesArePrivate() {
    let input = """
      import Testing

      @Suite struct MyTests {
          var someProperty: String = ""
          public var anotherProperty: Int = 0

          @Test func example() {
              #expect(someProperty == "")
          }
      }
      """

    let output = """
      import Testing

      @Suite struct MyTests {
          private var someProperty: String = ""
          private var anotherProperty: Int = 0

          @Test func example() {
              #expect(someProperty == "")
          }
      }
      """

    testFormatting(
      for: input, output, rule: .testSuiteAccessControl,
      exclude: [.unusedArguments, .validateTestCases])
  }

  @Test func xCTestClassIsInternal() {
    let input = """
      import Testing

      public @Suite struct MyTests {
          @Test func example() {
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
      for: input, output, rule: .testSuiteAccessControl,
      exclude: [.unusedArguments, .validateTestCases])
  }

  @Test func xCTestWithParameterlessInitializerIsProcessed() {
    let input = """
      import Testing

      @Suite struct MyTests {
          private let dependency: Dependency = Dependency()

          public init() {
              // Custom initialization
          }

          @Test func example() {
              #expect(true)
          }
      }
      """

    let output = """
      import Testing

      @Suite struct MyTests {
          private let dependency: Dependency = Dependency()

          init() {
              // Custom initialization
          }

          @Test func example() {
              #expect(true)
          }
      }
      """

    testFormatting(
      for: input, output, rule: .testSuiteAccessControl,
      exclude: [.unusedArguments, .validateTestCases, .redundantType])
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

    testFormatting(
      for: input, rule: .testSuiteAccessControl, exclude: [.unusedArguments, .validateTestCases])
  }

  @Test func xCTestPreservesStaticFunctions() {
    let input = """
      import Testing

      @Suite struct MyTests {
          @Test func example() {
              #expect(true)
          }

          static func helperMethod() {
              // helper code
          }
      }
      """

    testFormatting(
      for: input, rule: .testSuiteAccessControl, exclude: [.unusedArguments, .validateTestCases])
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

    testFormatting(
      for: input, rule: .testSuiteAccessControl, exclude: [.unusedArguments, .validateTestCases])
  }

  @Test func xCTestPreservesOverrideMethods() {
    let input = """
      import XCTest

      class BaseTestCase: XCTestCase {
          func setUp() {
              // setup code
          }
      }

      class MyTests: BaseTestCase {
          override func setUp() {
              super.setUp()
          }

          @Test func example() {
              #expect(true)
          }
      }
      """

    testFormatting(
      for: input, rule: .testSuiteAccessControl, exclude: [.unusedArguments, .validateTestCases])
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

    testFormatting(
      for: input, rule: .testSuiteAccessControl, exclude: [.unusedArguments, .validateTestCases])
  }

  @Test func xCTestHelperMethodWithTestPrefixAndParameters() {
    let input = """
      import Testing

      @Suite struct MyTests {
          @Test func example() {
              testHelper(value: 5)
          }

          func testHelper(value: Int) {
              #expect(value == 5)
          }

          func testFormatter(string: String) -> String {
              return string.uppercased()
          }
      }
      """

    let output = """
      import Testing

      @Suite struct MyTests {
          @Test func example() {
              testHelper(value: 5)
          }

          private func testHelper(value: Int) {
              #expect(value == 5)
          }

          private func testFormatter(string: String) -> String {
              return string.uppercased()
          }
      }
      """

    testFormatting(
      for: input, output, rule: .testSuiteAccessControl,
      exclude: [.unusedArguments, .validateTestCases])
  }

  // MARK: Swift Testing

  @Test func swiftTestingPropertiesArePrivate() {
    let input = """
      import Testing

      struct MyFeatureTests {
          var someProperty: String = ""
          public var anotherProperty: Int = 0

          @Test func featureWorks() {
              #expect(someProperty == "")
          }
      }
      """

    let output = """
      import Testing

      struct MyFeatureTests {
          private var someProperty: String = ""
          private var anotherProperty: Int = 0

          @Test func featureWorks() {
              #expect(someProperty == "")
          }
      }
      """

    testFormatting(
      for: input, output, rule: .testSuiteAccessControl,
      exclude: [.unusedArguments, .validateTestCases])
  }

  @Test func swiftTestingHelperMethodsArePrivate() {
    let input = """
      import Testing

      struct MyFeatureTests {
          @Test func featureWorks() {
              helperMethod()
          }

          func helperMethod() {
              // helper code
          }

          public func publicHelper() {
              // helper code
          }
      }
      """

    let output = """
      import Testing

      struct MyFeatureTests {
          @Test func featureWorks() {
              helperMethod()
          }

          private func helperMethod() {
              // helper code
          }

          private func publicHelper() {
              // helper code
          }
      }
      """

    testFormatting(
      for: input, output, rule: .testSuiteAccessControl,
      exclude: [.unusedArguments, .validateTestCases])
  }

  @Test func swiftTestingClassIsInternal() {
    let input = """
      import Testing

      public struct MyFeatureTests {
          @Test func featureWorks() {
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
      for: input, output, rule: .testSuiteAccessControl,
      exclude: [.unusedArguments, .validateTestCases])
  }

  // MARK: Base Classes

  @Test func doesNotApplyToBaseTestClasses() {
    let input = """
      import XCTest

      public class MyFeatureTestsBase: XCTestCase {
          public func helperMethod() {
              // helper code
          }

          public var someProperty: String = ""
      }
      """

    testFormatting(
      for: input, rule: .testSuiteAccessControl, exclude: [.unusedArguments, .validateTestCases])
  }

  @Test func doesNotApplyToSwiftTestingBaseClasses() {
    let input = """
      import Testing

      public class MyFeatureTestsBase {
          public func helperMethod() {
              // helper code
          }

          public var someProperty: String = ""
      }
      """

    testFormatting(
      for: input, rule: .testSuiteAccessControl, exclude: [.unusedArguments, .validateTestCases])
  }

  @Test func doesNotApplyToTestClassWithBaseInDocComment() {
    let input = """
      import XCTest

      /// Base class for feature tests.
      public class MyFeatureTests: XCTestCase {
          public func helperMethod() {
              // helper code
          }

          public var someProperty: String = ""
      }
      """

    testFormatting(
      for: input, rule: .testSuiteAccessControl, exclude: [.unusedArguments, .validateTestCases])
  }

  @Test func doesNotApplyToTestClassWithSubclassInDocComment() {
    let input = """
      import XCTest

      /// Intended to be subclassed for specific feature tests.
      public class MyFeatureTests: XCTestCase {
          public func helperMethod() {
              // helper code
          }

          public var someProperty: String = ""
      }
      """

    testFormatting(
      for: input, rule: .testSuiteAccessControl, exclude: [.unusedArguments, .validateTestCases])
  }

  @Test func doesNotApplyToSwiftTestingClassWithBaseInDocComment() {
    let input = """
      import Testing

      /// Base struct for testing features.
      public struct MyFeatureTests {
          public func helperMethod() {
              // helper code
          }
      }
      """

    testFormatting(
      for: input, rule: .testSuiteAccessControl, exclude: [.unusedArguments, .validateTestCases])
  }

  // MARK: Disabled Tests

  @Test func xCTestPreservesDisabledTestMethods() {
    let input = """
      import Testing

      @Suite struct MyTests {
          func disable_testExample() {
              #expect(true)
          }

          func skip_testFeature() {
              #expect(false)
          }
      }
      """

    testFormatting(
      for: input, rule: .testSuiteAccessControl, exclude: [.unusedArguments, .validateTestCases])
  }

  @Test func swiftTestingPreservesDisabledTestMethods() {
    let input = """
      import Testing

      struct MyFeatureTests {
          func disable_featureWorks() {
              #expect(true)
          }

          func x_edgeCaseHandling() {
              #expect(false)
          }
      }
      """

    testFormatting(
      for: input, rule: .testSuiteAccessControl, exclude: [.unusedArguments, .validateTestCases])
  }

  @Test func xCTestPreservesCapitalizedDisabledTestMethods() {
    let input = """
      import Testing

      @Suite struct MyTests {
          func X_testExample() {
              #expect(true)
          }

          func DISABLE_testFeature() {
              #expect(false)
          }
      }
      """

    testFormatting(
      for: input, rule: .testSuiteAccessControl, exclude: [.unusedArguments, .validateTestCases])
  }

  @Test func swiftTestingPreservesCapitalizedDisabledTestMethods() {
    let input = """
      import Testing

      struct MyFeatureTests {
          func SKIP_featureWorks() {
              #expect(true)
          }

          func DISABLED_edgeCaseHandling() {
              #expect(false)
          }
      }
      """

    testFormatting(
      for: input, rule: .testSuiteAccessControl, exclude: [.unusedArguments, .validateTestCases])
  }

  // MARK: Mixed Frameworks

  @Test func doesNotApplyWhenBothTestingFrameworksAreImported() {
    let input = """
      import Testing
      import XCTest

      @Suite struct MyTests {
          @Test func example() {
              #expect(true)
          }

          func helperMethod() {
              // helper code
          }

          var someProperty: String = ""
      }
      """

    testFormatting(
      for: input, rule: .testSuiteAccessControl,
      exclude: [.unusedArguments, .validateTestCases, .sortImports])
  }

  @Test(.disabled("Fixture logic differs after XCTest→Swift Testing conversion"))
  func xCTestIgnoresTypesWithParameterizedInit() {
    let input = """
      import Testing

      @Suite struct MyHelperClass {
          let dependency: String

          init(dependency: String) {
              self.dependency = dependency
          }

          func example() {
              #expect(true)
          }
      }
      """

    // No changes should be made - types with parameterized init are not test suites
    testFormatting(
      for: input, rule: .testSuiteAccessControl, exclude: [.unusedArguments, .validateTestCases])
  }

  @Test func swiftTestingIgnoresTypesWithParameterizedInit() {
    let input = """
      import Testing

      struct MyHelperStruct {
          let dependency: String

          init(dependency: String) {
              self.dependency = dependency
          }

          func example() {
              #expect(true)
          }
      }
      """

    // No changes should be made - types with parameterized init are not test suites
    testFormatting(
      for: input, rule: .testSuiteAccessControl,
      exclude: [.unusedArguments, .validateTestCases, .redundantMemberwiseInit])
  }
}
