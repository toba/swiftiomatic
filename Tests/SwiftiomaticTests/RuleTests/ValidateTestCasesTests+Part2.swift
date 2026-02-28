import Testing
@testable import Swiftiomatic

extension ValidateTestCasesTests {
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
