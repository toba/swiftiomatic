import Testing
@testable import Swiftiomatic

extension NoGuardInTestsTests {
    @Test func swiftTestingAddsThrows() {
        let input = """
        import Testing

        struct SomeTests {
            @Test
            func something() {
                guard let value = optionalValue else {
                    return
                }
            }
        }
        """
        let output = """
        import Testing

        struct SomeTests {
            @Test
            func something() throws {
                let value = try #require(optionalValue)
            }
        }
        """
        testFormatting(for: input, output, rule: .noGuardInTests, exclude: [.elseOnSameLine])
    }

    @Test func swiftTestingPreservesExistingThrows() {
        let input = """
        import Testing

        struct SomeTests {
            @Test
            func something() throws {
                guard let value = optionalValue else {
                    return
                }
            }
        }
        """
        let output = """
        import Testing

        struct SomeTests {
            @Test
            func something() throws {
                let value = try #require(optionalValue)
            }
        }
        """
        testFormatting(for: input, output, rule: .noGuardInTests, exclude: [.elseOnSameLine])
    }

    @Test func swiftTestingAsyncFunction() {
        let input = """
        import Testing

        struct SomeTests {
            @Test
            func something() async {
                let optionalValue = await function()
                guard let value = optionalValue else {
                    return
                }
            }
        }
        """
        let output = """
        import Testing

        struct SomeTests {
            @Test
            func something() async throws {
                let optionalValue = await function()
                let value = try #require(optionalValue)
            }
        }
        """
        testFormatting(for: input, output, rule: .noGuardInTests)
    }

    @Test func swiftTestingMultipleGuardStatements() {
        let input = """
        import Testing

        struct SomeTests {
            @Test
            func something() {
                guard let value1 = optionalValue1 else {
                    return
                }
                guard let value2 = optionalValue2 else {
                    return
                }
            }
        }
        """
        let output = """
        import Testing

        struct SomeTests {
            @Test
            func something() throws {
                let value1 = try #require(optionalValue1)
                let value2 = try #require(optionalValue2)
            }
        }
        """
        testFormatting(
            for: input, output, rule: .noGuardInTests, exclude: [.blankLinesAfterGuardStatements],
        )
    }

    @Test func replaceGuardWithMultipleConditionsSwiftTesting() {
        let input = """
        import Testing

        struct SomeTests {
            @Test
            func something() {
                guard let value = optionalValue,
                      someCondition else {
                    return
                }
            }
        }
        """
        let output = """
        import Testing

        struct SomeTests {
            @Test
            func something() throws {
                let value = try #require(optionalValue)
                #expect(someCondition)
            }
        }
        """
        testFormatting(for: input, output, rule: .noGuardInTests)
    }

    @Test func replaceMultipleOptionalBindingsSwiftTesting() {
        let input = """
        import Testing

        struct SomeTests {
            @Test
            func something() {
                guard let value = optionalValue,
                      let other = otherValue else {
                    return
                }
            }
        }
        """
        let output = """
        import Testing

        struct SomeTests {
            @Test
            func something() throws {
                let value = try #require(optionalValue)
                let other = try #require(otherValue)
            }
        }
        """
        testFormatting(for: input, output, rule: .noGuardInTests)
    }

    @Test func replaceGuardIssueRecordWithRequire() {
        let input = """
        import Testing

        struct SomeTests {
            @Test
            func something() {
                guard let value = optionalValue else {
                    Issue.record()
                    return
                }
                print(value)
            }
        }
        """
        let output = """
        import Testing

        struct SomeTests {
            @Test
            func something() throws {
                let value = try #require(optionalValue)
                print(value)
            }
        }
        """
        testFormatting(
            for: input, output, rule: .noGuardInTests, exclude: [.blankLinesAfterGuardStatements],
        )
    }

    @Test func replaceGuardIssueRecordWithMessageWithRequire() {
        let input = """
        import Testing

        struct SomeTests {
            @Test
            func something() {
                guard let value = optionalValue else {
                    Issue.record("Expected value to be non-nil")
                    return
                }
            }
        }
        """
        let output = """
        import Testing

        struct SomeTests {
            @Test
            func something() throws {
                let value = try #require(optionalValue, "Expected value to be non-nil")
            }
        }
        """
        testFormatting(for: input, output, rule: .noGuardInTests)
    }

    @Test func nonUnwrapConditionsDontInsertThrows() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard condition, optionalValue != nil else {
                    XCTFail()
                    return
                }
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                XCTAssert(condition)
                XCTAssert(optionalValue != nil)
            }
        }
        """
        testFormatting(for: input, output, rule: .noGuardInTests)
    }

    // MARK: - Variable shadowing tests

    @Test func doesNotReplaceWhenVariableShadowing() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                let foo: String? = ""
                guard let foo else {
                    XCTFail()
                    return
                }
            }
        }
        """
        testFormatting(for: input, rule: .noGuardInTests)
    }

    @Test func doesNotReplaceWhenVariableShadowingWithReturn() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                let value: String? = ""
                guard let value else {
                    return
                }
            }
        }
        """
        testFormatting(for: input, rule: .noGuardInTests)
    }

    @Test func handlesGuardLetShorthand() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            private var optionalValue: String?

            func test_something() {
                guard let optionalValue else {
                    XCTFail()
                    return
                }
                print(optionalValue)
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            private var optionalValue: String?

            func test_something() throws {
                let optionalValue = try XCTUnwrap(optionalValue)
                print(optionalValue)
            }
        }
        """
        testFormatting(
            for: input, output, rule: .noGuardInTests, exclude: [.blankLinesAfterGuardStatements],
        )
    }

    @Test func handlesGuardLetShorthandSwiftTesting() {
        let input = """
        import Testing

        struct SomeTests {
            @Test
            func something(value: String?) {
                guard let value else {
                    return
                }
                print(value)
            }
        }
        """
        let output = """
        import Testing

        struct SomeTests {
            @Test
            func something(value: String?) throws {
                let value = try #require(value)
                print(value)
            }
        }
        """
        testFormatting(
            for: input, output, rule: .noGuardInTests, exclude: [.blankLinesAfterGuardStatements],
        )
    }

    @Test func handlesExplicitTypeAnnotation() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard var foo: Foo = getFoo() else {
                    XCTFail()
                    return
                }
                foo = otherFoo
                print(foo)
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                var foo: Foo = try XCTUnwrap(getFoo())
                foo = otherFoo
                print(foo)
            }
        }
        """
        testFormatting(
            for: input, output, rule: .noGuardInTests, exclude: [.blankLinesAfterGuardStatements],
        )
    }

    @Test func handlesExplicitTypeAnnotationWithShorthand() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard let foo, let bar: Bar else {
                    XCTFail()
                    return
                }
                print(foo, bar)
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                let foo = try XCTUnwrap(foo)
                let bar: Bar = try XCTUnwrap(bar)
                print(foo, bar)
            }
        }
        """
        testFormatting(
            for: input, output, rule: .noGuardInTests, exclude: [.blankLinesAfterGuardStatements],
        )
    }

    @Test func handlesComplexTypeAnnotation() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard let value: [String: Any] = getDictionary() else {
                    return
                }
                print(value)
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                let value: [String: Any] = try XCTUnwrap(getDictionary())
                print(value)
            }
        }
        """
        testFormatting(
            for: input, output, rule: .noGuardInTests, exclude: [.blankLinesAfterGuardStatements],
        )
    }

    @Test func handlesTypeAnnotationSwiftTesting() {
        let input = """
        import Testing

        struct SomeTests {
            @Test
            func something() {
                guard let result: Result<String, Error> = getResult() else {
                    return
                }
                print(result)
            }
        }
        """
        let output = """
        import Testing

        struct SomeTests {
            @Test
            func something() throws {
                let result: Result<String, Error> = try #require(getResult())
                print(result)
            }
        }
        """
        testFormatting(
            for: input, output, rule: .noGuardInTests, exclude: [.blankLinesAfterGuardStatements],
        )
    }

    @Test func preservesDependentConditions() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                let result = sut.contentAsGalleryMediaItems.first
                guard let result, let image = result.image else {
                    XCTFail("gallery media item expected to be an image type")
                    return
                }
                print(image)
            }
        }
        """
        testFormatting(
            for: input,
            rule: .noGuardInTests,
            exclude: [.blankLinesAfterGuardStatements],
        )
    }

    @Test func convertsBooleanConditionsToXCTAssert() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard someCondition,
                      let value = optionalValue else {
                    XCTFail()
                    return
                }
                print(value)
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                XCTAssert(someCondition)
                let value = try XCTUnwrap(optionalValue)
                print(value)
            }
        }
        """
        testFormatting(
            for: input, output, rule: .noGuardInTests,
            exclude: [.blankLinesAfterGuardStatements, .unusedArguments],
        )
    }

    @Test func convertsBooleanConditionsToExpect() {
        let input = """
        import Testing

        struct SomeTests {
            @Test
            func something() {
                guard someCondition,
                      let value = optionalValue else {
                    return
                }
                print(value)
            }
        }
        """
        let output = """
        import Testing

        struct SomeTests {
            @Test
            func something() throws {
                #expect(someCondition)
                let value = try #require(optionalValue)
                print(value)
            }
        }
        """
        testFormatting(
            for: input, output, rule: .noGuardInTests, exclude: [.blankLinesAfterGuardStatements],
        )
    }

    @Test func convertsMultipleBooleanConditions() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard condition1,
                      condition2,
                      let value = optionalValue,
                      condition3 else {
                    XCTFail()
                    return
                }
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                XCTAssert(condition1)
                XCTAssert(condition2)
                let value = try XCTUnwrap(optionalValue)
                XCTAssert(condition3)
            }
        }
        """
        testFormatting(for: input, output, rule: .noGuardInTests)
    }

    @Test func preservesGuardWithShadowedVariable() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                let foo = "existing"
                guard someCondition,
                      let foo = optionalFoo else {
                    XCTFail()
                    return
                }
                print(foo)
            }
        }
        """
        testFormatting(
            for: input, rule: .noGuardInTests,
            exclude: [
                .blankLinesAfterGuardStatements,
                .elseOnSameLine,
                .wrapMultilineStatementBraces,
            ],
        )
    }

    @Test func preservesGuardWithAnyShadowing() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                let bar = "existing"
                guard someCondition,
                      let foo = optionalFoo,
                      let bar = optionalBar else {
                    XCTFail()
                    return
                }
                print(foo, bar)
            }
        }
        """
        // Since bar is shadowed, we preserve the entire guard
        testFormatting(
            for: input, rule: .noGuardInTests,
            exclude: [
                .blankLinesAfterGuardStatements,
                .elseOnSameLine,
                .wrapMultilineStatementBraces,
            ],
        )
    }

    @Test func preservesGuardWithMixedCasePattern() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard let foo = optionalFoo,
                      case .success(let value) = result else {
                    XCTFail()
                    return
                }
                print(foo, value)
            }
        }
        """
        testFormatting(
            for: input, rule: .noGuardInTests,
            exclude: [
                .blankLinesAfterGuardStatements, .hoistPatternLet, .elseOnSameLine,
                .wrapMultilineStatementBraces,
            ],
        )
    }

    // MARK: - Await tests

    @Test func preservesGuardWithAwaitInCondition() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() async {
                guard let value = await getAsyncValue() else {
                    XCTFail()
                    return
                }
                print(value)
            }
        }
        """
        testFormatting(
            for: input,
            rule: .noGuardInTests,
            exclude: [.blankLinesAfterGuardStatements],
        )
    }

    @Test func preservesGuardWithAwaitInConditionSwiftTesting() {
        let input = """
        import Testing

        struct SomeTests {
            @Test
            func something() async {
                guard let value = await getAsyncValue() else {
                    return
                }
                print(value)
            }
        }
        """
        testFormatting(
            for: input,
            rule: .noGuardInTests,
            exclude: [.blankLinesAfterGuardStatements],
        )
    }

    @Test func preservesGuardWithAwaitInMultipleConditions() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() async {
                guard let value1 = optionalValue,
                      let value2 = await getAsyncValue() else {
                    XCTFail()
                    return
                }
                print(value1, value2)
            }
        }
        """
        testFormatting(
            for: input, rule: .noGuardInTests,
            exclude: [
                .blankLinesAfterGuardStatements,
                .elseOnSameLine,
                .wrapMultilineStatementBraces,
            ],
        )
    }

    // MARK: - No import tests

    @Test func doesNothingWithoutImport() {
        let input = """
        func test_something() {
            guard let value = optionalValue else {
                return
            }
        }
        """
        testFormatting(for: input, rule: .noGuardInTests)
    }
}
