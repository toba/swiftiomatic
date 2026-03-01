import Testing
@testable import Swiftiomatic

@Suite struct NoGuardInTestsTests {
    // MARK: - XCTest tests

    @Test func replaceGuardXCTFailWithXCTUnwrap() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard let value = optionalValue else {
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
                let value = try XCTUnwrap(optionalValue)
                print(value)
            }
        }
        """
        testFormatting(
            for: input, output, rule: .noGuardInTests, exclude: [.blankLinesAfterGuardStatements],
        )
    }

    @Test func replaceGuardXCTFailWithMessageWithXCTUnwrap() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard let value = optionalValue else {
                    XCTFail("Expected value to be non-nil")
                    return
                }
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                let value = try XCTUnwrap(optionalValue, "Expected value to be non-nil")
            }
        }
        """
        testFormatting(for: input, output, rule: .noGuardInTests)
    }

    @Test func doesNotReplaceNonTestFunction() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func helper() {
                guard let value = optionalValue else {
                    XCTFail()
                    return
                }
            }
        }
        """
        testFormatting(
            for: input, rule: .noGuardInTests, exclude: [
                .testSuiteAccessControl,
                .validateTestCases,
            ],
        )
    }

    @Test func doesNotReplaceGuardWithDifferentElseBlock() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard let value = optionalValue else {
                    print("no value")
                    return
                }
            }
        }
        """
        testFormatting(for: input, rule: .noGuardInTests)
    }

    @Test func replacesGuardWithDifferentExpression() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard let value = getDifferentValue() else {
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
                let value = try XCTUnwrap(getDifferentValue())
            }
        }
        """
        testFormatting(for: input, output, rule: .noGuardInTests)
    }

    @Test func doesNotReplaceInClosure() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                doSomething {
                    guard let value = optionalValue else {
                        XCTFail()
                        return
                    }
                }
            }
        }
        """
        testFormatting(for: input, rule: .noGuardInTests)
    }

    @Test func doesNotReplaceInNestedFunc() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                func doSomething() {
                    guard let value = optionalValue else {
                        XCTFail()
                        return
                    }
                }
            }
        }
        """
        testFormatting(for: input, rule: .noGuardInTests)
    }

    @Test func preservesExistingThrows() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                guard let value = optionalValue else {
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
                let value = try XCTUnwrap(optionalValue)
            }
        }
        """
        testFormatting(for: input, output, rule: .noGuardInTests)
    }

    @Test func handlesAsyncFunction() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() async {
                let optionalValue = await function()
                guard let value = optionalValue else {
                    XCTFail()
                    return
                }
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() async throws {
                let optionalValue = await function()
                let value = try XCTUnwrap(optionalValue)
            }
        }
        """
        testFormatting(for: input, output, rule: .noGuardInTests)
    }

    @Test func replaceGuardReturnWithXCTUnwrap() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard let value = optionalValue else {
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
                let value = try XCTUnwrap(optionalValue)
                print(value)
            }
        }
        """
        testFormatting(
            for: input, output, rule: .noGuardInTests, exclude: [.blankLinesAfterGuardStatements],
        )
    }

    @Test func multipleGuardStatements() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard let value1 = optionalValue1 else {
                    XCTFail()
                    return
                }
                guard let value2 = optionalValue2 else {
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
                let value1 = try XCTUnwrap(optionalValue1)
                let value2 = try XCTUnwrap(optionalValue2)
            }
        }
        """
        testFormatting(
            for: input, output, rule: .noGuardInTests, exclude: [.blankLinesAfterGuardStatements],
        )
    }

    @Test func preserveFailMessage() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard let value1 = optionalValue1 else {
                    XCTFail("Failed")
                    return
                }
                guard optionalValue2 != nil else {
                    XCTFail("Value was nil")
                    return
                }
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                let value1 = try XCTUnwrap(optionalValue1, "Failed")
                XCTAssert(optionalValue2 != nil, "Value was nil")
            }
        }
        """
        testFormatting(
            for: input, output, rule: .noGuardInTests, exclude: [.blankLinesAfterGuardStatements],
        )
    }

    @Test func preserveFailMessageWithInterpolations() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard optionalValue2 == nil else {
                    XCTFail("Value was \\(String(describing: optionalValue2))")
                    return
                }
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                XCTAssert(optionalValue2 == nil, "Value was \\(String(describing: optionalValue2))")
            }
        }
        """
        testFormatting(
            for: input, output, rule: .noGuardInTests, exclude: [.blankLinesAfterGuardStatements],
        )
    }

    @Test func noMangleNontrivialGuardBody() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard optionalValue2 == nil else {
                    let value = optionalValue2 ?? ""
                    XCTFail("Value was \\(value)")
                    return
                }
            }
        }
        """
        testFormatting(
            for: input,
            rule: .noGuardInTests,
            exclude: [.blankLinesAfterGuardStatements],
        )
    }

    @Test func replaceGuardWithMultipleConditionsXCTest() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard let value = optionalValue,
                      let other = otherValue else {
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
                let value = try XCTUnwrap(optionalValue)
                let other = try XCTUnwrap(otherValue)
            }
        }
        """
        testFormatting(for: input, output, rule: .noGuardInTests)
    }

    @Test func doesNotReplaceAllConditionsInMultipleGuard() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard someCondition,
                      let value = optionalValue else {
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
                XCTAssert(someCondition)
                let value = try XCTUnwrap(optionalValue)
            }
        }
        """
        testFormatting(for: input, output, rule: .noGuardInTests)
    }

    @Test func replaceMultipleGuardConditionsWithMixedPatterns() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard let value = optionalValue,
                      someCondition,
                      let other = otherValue else {
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
                let value = try XCTUnwrap(optionalValue)
                XCTAssert(someCondition)
                let other = try XCTUnwrap(otherValue)
            }
        }
        """
        testFormatting(for: input, output, rule: .noGuardInTests)
    }

    @Test func simpleMultipleConditions() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard let value = optionalValue, condition else {
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
                let value = try XCTUnwrap(optionalValue)
                XCTAssert(condition)
            }
        }
        """
        testFormatting(for: input, output, rule: .noGuardInTests)
    }

    @Test func simpleMultipleConditions2() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard condition, 
                    let value = optionalValue
                else { XCTFail()
                    return }
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                XCTAssert(condition)
                let value = try XCTUnwrap(optionalValue)
            }
        }
        """
        testFormatting(for: input, output, rule: .noGuardInTests, exclude: [.wrapConditionalBodies])
    }

    @Test func handlesFiveConditions() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard let value1 = optional1,
                      let value2 = optional2,
                      let value3 = optional3,
                      let value4 = optional4,
                      let value5 = optional5 else {
                    XCTFail()
                    return
                }
                print(value1, value2, value3, value4, value5)
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                let value1 = try XCTUnwrap(optional1)
                let value2 = try XCTUnwrap(optional2)
                let value3 = try XCTUnwrap(optional3)
                let value4 = try XCTUnwrap(optional4)
                let value5 = try XCTUnwrap(optional5)
                print(value1, value2, value3, value4, value5)
            }
        }
        """
        testFormatting(
            for: input, output, rule: .noGuardInTests,
            exclude: [
                .wrapMultilineStatementBraces, .elseOnSameLine, .blankLinesAfterGuardStatements,
                .wrapArguments,
            ],
        )
    }

    @Test func handlesTenConditions() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard let value1 = optional1,
                      let value2 = optional2,
                      let value3 = optional3,
                      let value4 = optional4,
                      let value5 = optional5,
                      let value6 = optional6,
                      let value7 = optional7,
                      let value8 = optional8,
                      let value9 = optional9,
                      let value10 = optional10 else {
                    XCTFail()
                    return
                }
                print(value1, value2, value3, value4, value5, value6, value7, value8, value9, value10)
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                let value1 = try XCTUnwrap(optional1)
                let value2 = try XCTUnwrap(optional2)
                let value3 = try XCTUnwrap(optional3)
                let value4 = try XCTUnwrap(optional4)
                let value5 = try XCTUnwrap(optional5)
                let value6 = try XCTUnwrap(optional6)
                let value7 = try XCTUnwrap(optional7)
                let value8 = try XCTUnwrap(optional8)
                let value9 = try XCTUnwrap(optional9)
                let value10 = try XCTUnwrap(optional10)
                print(value1, value2, value3, value4, value5, value6, value7, value8, value9, value10)
            }
        }
        """
        testFormatting(
            for: input, output, rule: .noGuardInTests,
            exclude: [.blankLinesAfterGuardStatements, .acronyms],
        )
    }

    @Test func handlesMixedComplexConditions() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard condition1,
                      let value1 = optional1,
                      condition2,
                      let value2 = optional2,
                      let value3 = optional3,
                      condition3,
                      let value4 = optional4,
                      let value5 = optional5,
                      condition4,
                      let value6 = optional6,
                      condition5 else {
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
                let value1 = try XCTUnwrap(optional1)
                XCTAssert(condition2)
                let value2 = try XCTUnwrap(optional2)
                let value3 = try XCTUnwrap(optional3)
                XCTAssert(condition3)
                let value4 = try XCTUnwrap(optional4)
                let value5 = try XCTUnwrap(optional5)
                XCTAssert(condition4)
                let value6 = try XCTUnwrap(optional6)
                XCTAssert(condition5)
            }
        }
        """
        testFormatting(
            for: input, output, rule: .noGuardInTests,
            exclude: [
                .wrapMultilineStatementBraces, .elseOnSameLine, .blankLinesAfterGuardStatements,
                .wrapArguments,
            ],
        )
    }

    // MARK: - Swift Testing tests

    @Test func replaceGuardReturnWithRequire() {
        let input = """
        import Testing

        struct SomeTests {
            @Test
            func something() {
                guard let value = optionalValue else {
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

    @Test func doesNotReplaceNonTestFunctionSwiftTesting() {
        let input = """
        import Testing

        struct SomeTests {
            func helper() {
                guard let value = optionalValue else {
                    return
                }
            }
        }
        """
        testFormatting(
            for: input, rule: .noGuardInTests, exclude: [
                .testSuiteAccessControl,
                .validateTestCases,
            ],
        )
    }

    @Test func doesNotReplaceGuardWithDifferentElseBlockSwiftTesting() {
        let input = """
        import Testing

        struct SomeTests {
            @Test
            func something() {
                guard let value = optionalValue else {
                    print("no value")
                    return
                }
            }
        }
        """
        testFormatting(for: input, rule: .noGuardInTests)
    }

    @Test func doesNotReplaceInClosureSwiftTesting() {
        let input = """
        import Testing

        struct SomeTests {
            @Test
            func something() {
                doSomething {
                    guard let value = optionalValue else {
                        return
                    }
                }
            }
        }
        """
        testFormatting(for: input, rule: .noGuardInTests)
    }

}
