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
            for: input, rule: .validateTestCases, exclude: [
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

    @Test func doesNotApplyWhenBothTestingFrameworksAreImported() {
        // When both Testing and XCTest are imported, it's ambiguous which framework to use
        let input = """
        import Testing
        import XCTest

        @Suite struct MyTests {
            public func example() {
                #expect(true)
            }

            var someProperty: String = ""
        }
        """

        // Should not make any changes when both frameworks are imported
        testFormatting(
            for: input, rule: .validateTestCases, exclude: [.unusedArguments, .redundantPublic],
        )
    }

    @Test func doesNotApplyToBaseTestClasses() {
        // Base test classes (with "Base" in name) should not have access control modified
        let input = """
        import XCTest

        open class MyFeatureTestsBase: XCTestCase {
            public func helperMethod() {
                // This should remain public for subclasses
            }

            public var sharedProperty: String = ""

            public func example() {
                #expect(true)
            }
        }
        """

        testFormatting(
            for: input, rule: .validateTestCases, exclude: [.unusedArguments, .redundantPublic],
        )
    }

    @Test func doesNotApplyToSwiftTestingBaseClasses() {
        // Base test classes (with "Base" in name) should not have access control modified
        let input = """
        import Testing

        open class FeatureTestBase {
            public func helperMethod() {
                // This should remain public for subclasses
            }

            public var sharedProperty: String = ""

            public func example() {
                #expect(true)
            }
        }
        """

        testFormatting(
            for: input, rule: .validateTestCases, exclude: [.unusedArguments, .redundantPublic],
        )
    }

    @Test func doesNotApplyToTestClassWithBaseInDocComment() {
        // Test classes with "base" mentioned in doc comment should not be modified
        let input = """
        import XCTest

        /// Base class for feature tests
        open class MyFeatureTests: XCTestCase {
            public func helperMethod() {
                // This should remain public for subclasses
            }

            public var sharedProperty: String = ""

            public func example() {
                #expect(true)
            }
        }
        """

        testFormatting(
            for: input, rule: .validateTestCases, exclude: [.unusedArguments, .redundantPublic],
        )
    }

    @Test func doesNotApplyToTestClassWithSubclassInDocComment() {
        // Test classes with "subclass" mentioned in doc comment should not be modified
        let input = """
        import XCTest

        /// Meant to be subclassed by other test suites.
        /// Provides common test functionality.
        open class CommonTests: XCTestCase {
            public func helperMethod() {
                // This should remain public for subclasses
            }

            public var sharedProperty: String = ""

            public func example() {
                #expect(true)
            }
        }
        """

        testFormatting(
            for: input, rule: .validateTestCases, exclude: [.unusedArguments, .redundantPublic],
        )
    }

    @Test func doesNotApplyToSwiftTestingClassWithBaseInDocComment() {
        // Swift Testing classes with "base" in doc comment should not be modified
        let input = """
        import Testing

        /// Base test suite for features
        struct FeatureTests {
            public func helperMethod() {
                // This should remain public for subclasses
            }

            public var sharedProperty: String = ""

            public func example() {
                #expect(true)
            }
        }
        """

        testFormatting(
            for: input, rule: .validateTestCases, exclude: [.unusedArguments, .redundantPublic],
        )
    }

    @Test func xCTestPreservesDisabledTestMethods() {
        // Methods with disabled test prefixes should not have test prefix added
        let input = """
        import Testing

        @Suite struct MyTests {
            func disable_example() {
                #expect(true)
            }

            func disabled_anotherTest() {
                #expect(true)
            }

            func skip_thisTest() {
                #expect(true)
            }

            func skipped_obsolete() {
                #expect(true)
            }

            func x_broken() {
                #expect(true)
            }

            @Test func enabled() {
                #expect(true)
            }
        }
        """

        // No changes expected - disabled test methods don't get test prefix
        testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments])
    }

    @Test func swiftTestingPreservesDisabledTestMethods() {
        // Methods with disabled test prefixes should not have @Test attribute added
        let input = """
        import Testing

        struct MyFeatureTests {
            func disable_example() {
                #expect(true)
            }

            func disabled_anotherTest() {
                #expect(true)
            }

            func skip_thisTest() {
                #expect(true)
            }

            func skipped_obsolete() {
                #expect(true)
            }

            func x_broken() {
                #expect(true)
            }

            func enabled() {
                #expect(true)
            }
        }
        """

        let output = """
        import Testing

        struct MyFeatureTests {
            func disable_example() {
                #expect(true)
            }

            func disabled_anotherTest() {
                #expect(true)
            }

            func skip_thisTest() {
                #expect(true)
            }

            func skipped_obsolete() {
                #expect(true)
            }

            func x_broken() {
                #expect(true)
            }

            @Test func enabled() {
                #expect(true)
            }
        }
        """

        testFormatting(
            for: input, output, rule: .validateTestCases,
            exclude: [.unusedArguments, .testSuiteAccessControl],
        )
    }

    @Test func swiftTestingPreservesParameterizedTests() {
        // Parameterized tests with @Test(arguments:) should be left as-is
        let input = """
        import Testing

        struct FoodTests {
            @Test(arguments: [Food.burger, .iceCream, .burrito, .noodleBowl, .kebab])
            func foodAvailable(_ food: Food) async throws {
                let foodTruck = FoodTruck(selling: food)
                #expect(await foodTruck.cook(food))
            }

            @Test(arguments: [1, 2, 3, 4, 5])
            func numberIsValid(_ number: Int) {
                #expect(number > 0)
            }
        }
        """

        // Should not modify parameterized tests - they already have @Test
        testFormatting(
            for: input, rule: .validateTestCases, exclude: [.unusedArguments, .redundantThrows],
        )
    }

    @Test func xCTestPreservesCapitalizedDisabledTestMethods() {
        // Capitalized disabled test prefixes should also be preserved
        let input = """
        import Testing

        @Suite struct MyTests {
            func DISABLE_example() {
                #expect(true)
            }

            func X_broken() {
                #expect(true)
            }

            func Skip_ThisTest() {
                #expect(true)
            }

            @Test func enabled() {
                #expect(true)
            }
        }
        """

        // No changes expected - disabled test methods don't get test prefix
        testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments])
    }

    @Test func swiftTestingPreservesCapitalizedDisabledTestMethods() {
        // Capitalized disabled test prefixes should also be preserved
        let input = """
        import Testing

        struct MyFeatureTests {
            func DISABLE_example() {
                #expect(true)
            }

            func X_broken() {
                #expect(true)
            }

            func Skip_ThisTest() {
                #expect(true)
            }

            func enabled() {
                #expect(true)
            }
        }
        """

        let output = """
        import Testing

        struct MyFeatureTests {
            func DISABLE_example() {
                #expect(true)
            }

            func X_broken() {
                #expect(true)
            }

            func Skip_ThisTest() {
                #expect(true)
            }

            @Test func enabled() {
                #expect(true)
            }
        }
        """

        testFormatting(
            for: input, output, rule: .validateTestCases,
            exclude: [.unusedArguments, .testSuiteAccessControl],
        )
    }

    @Test func swiftTestingAddsTestAttributeWhenNameMatchesIdentifier() {
        let input = """
        import Testing

        struct ComponentTests {
            func button() {
                let button = Button()
                #expect(button.isEnabled)
            }

            func slider() {
                let value = slider(initialValue: 50)
                #expect(value == 50)
            }
        }
        """

        let output = """
        import Testing

        struct ComponentTests {
            @Test func button() {
                let button = Button()
                #expect(button.isEnabled)
            }

            @Test func slider() {
                let value = slider(initialValue: 50)
                #expect(value == 50)
            }
        }
        """

        testFormatting(
            for: input, output, rule: .validateTestCases,
            exclude: [.unusedArguments, .testSuiteAccessControl],
        )
    }

    @Test func xCTestPreservesPrivateFunctions() {
        // Private functions should not be treated as tests
        let input = """
        import Testing

        @Suite struct MyTests {
            @Test func example() {
                #expect(true)
            }

            private func helperMethod() {
                // This is a helper, should stay private
            }
        }
        """

        testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments])
    }

    @Test func swiftTestingPreservesPrivateFunctions() {
        // Private functions should not be treated as tests
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test func featureWorks() {
                #expect(true)
            }

            private func helperMethod() {
                // This is a helper, should stay private
            }
        }
        """

        testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments])
    }

    @Test func xCTestPreservesUnderscorePrefixedFunctions() {
        // Functions starting with underscore are treated as disabled
        let input = """
        import Testing

        @Suite struct MyTests {
            func _temporarilyDisabled() {
                #expect(true)
            }

            @Test func enabled() {
                #expect(true)
            }
        }
        """

        // No changes expected - underscore prefix means disabled
        testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments])
    }

    @Test func swiftTestingPreservesUnderscorePrefixedFunctions() {
        // Functions starting with underscore are treated as disabled
        let input = """
        import Testing

        struct MyFeatureTests {
            func _temporarilyDisabled() {
                #expect(true)
            }

            func enabled() {
                #expect(true)
            }
        }
        """

        let output = """
        import Testing

        struct MyFeatureTests {
            func _temporarilyDisabled() {
                #expect(true)
            }

            @Test func enabled() {
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
    func xCTestIgnoresTypesWithParameterizedInit() {
        // Types with parameterized initializers are not test suites
        let input = """
        import Testing

        @Suite struct MyTests {
            let dependency: Dependency

            init(dependency: Dependency) {
                self.dependency = dependency
            }

            func example() {
                #expect(true)
            }
        }
        """

        // No changes expected - has parameterized init
        testFormatting(
            for: input, rule: .validateTestCases, exclude: [
                .unusedArguments,
                .testSuiteAccessControl,
            ],
        )
    }

    @Test func swiftTestingIgnoresTypesWithParameterizedInit() {
        // Types with parameterized initializers are not test suites
        let input = """
        import Testing

        struct MyFeatureTests {
            let dependency: Dependency

            init(dependency: Dependency) {
                self.dependency = dependency
            }

            func example() {
                #expect(true)
            }
        }
        """

        // No changes expected - has parameterized init
        testFormatting(
            for: input, rule: .validateTestCases,
            exclude: [.unusedArguments, .testSuiteAccessControl, .redundantMemberwiseInit],
        )
    }
}
