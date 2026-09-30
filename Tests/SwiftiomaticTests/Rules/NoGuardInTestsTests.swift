import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct NoGuardInTestsTests: RuleTesting {
    // MARK: - XCTest: Basic guard replacement

    @Test func replaceGuardXCTFailWithXCTUnwrap() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
                import XCTest

                class TestCase: XCTestCase {
                    func test_something() {
                        1️⃣guard let value = optionalValue else {
                            XCTFail()
                            return
                        }
                        print(value)
                    }
                }
                """,
            expected: """
                import XCTest

                class TestCase: XCTestCase {
                    func test_something() throws {
                        let value = try XCTUnwrap(optionalValue)
                        print(value)
                    }
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap")
            ]
        )
    }

    @Test func replaceGuardXCTFailWithMessage() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
                import XCTest

                class TestCase: XCTestCase {
                    func test_something() {
                        1️⃣guard let value = optionalValue else {
                            XCTFail("Expected value to be non-nil")
                            return
                        }
                    }
                }
                """,
            expected: """
                import XCTest

                class TestCase: XCTestCase {
                    func test_something() throws {
                        let value = try XCTUnwrap(optionalValue, "Expected value to be non-nil")
                    }
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap")
            ]
        )
    }

    @Test func replaceGuardReturnOnly() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
                import XCTest

                class TestCase: XCTestCase {
                    func test_something() {
                        1️⃣guard let value = optionalValue else {
                            return
                        }
                        print(value)
                    }
                }
                """,
            expected: """
                import XCTest

                class TestCase: XCTestCase {
                    func test_something() throws {
                        let value = try XCTUnwrap(optionalValue)
                        print(value)
                    }
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap")
            ]
        )
    }

    @Test func replacesDifferentExpression() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
                import XCTest

                class TestCase: XCTestCase {
                    func test_something() {
                        1️⃣guard let value = getDifferentValue() else {
                            XCTFail()
                            return
                        }
                    }
                }
                """,
            expected: """
                import XCTest

                class TestCase: XCTestCase {
                    func test_something() throws {
                        let value = try XCTUnwrap(getDifferentValue())
                    }
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap")
            ]
        )
    }

    // MARK: - XCTest: Multiple conditions

    @Test func multipleOptionalBindings() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
                import XCTest

                class TestCase: XCTestCase {
                    func test_something() {
                        1️⃣guard let value = optionalValue,
                              let other = otherValue else {
                            XCTFail()
                            return
                        }
                    }
                }
                """,
            expected: """
                import XCTest

                class TestCase: XCTestCase {
                    func test_something() throws {
                        let value = try XCTUnwrap(optionalValue)
                        let other = try XCTUnwrap(otherValue)
                    }
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap")
            ]
        )
    }

    @Test func preservesMixedGuardWithBooleanCondition() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
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
                """,
            expected: """
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
                """,
            findings: []
        )
    }

    @Test func preservesMixedConditionsWithBooleanInMiddle() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
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
                """,
            expected: """
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
                """,
            findings: []
        )
    }

    @Test func preservesBooleanOnlyGuard() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
                import XCTest

                class TestCase: XCTestCase {
                    func test_something() {
                        guard condition, optionalValue != nil else {
                            XCTFail()
                            return
                        }
                    }
                }
                """,
            expected: """
                import XCTest

                class TestCase: XCTestCase {
                    func test_something() {
                        guard condition, optionalValue != nil else {
                            XCTFail()
                            return
                        }
                    }
                }
                """,
            findings: []
        )
    }

    @Test func multipleGuardStatements() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
                import XCTest

                class TestCase: XCTestCase {
                    func test_something() {
                        1️⃣guard let value1 = optionalValue1 else {
                            XCTFail()
                            return
                        }
                        2️⃣guard let value2 = optionalValue2 else {
                            XCTFail()
                            return
                        }
                    }
                }
                """,
            expected: """
                import XCTest

                class TestCase: XCTestCase {
                    func test_something() throws {
                        let value1 = try XCTUnwrap(optionalValue1)
                        let value2 = try XCTUnwrap(optionalValue2)
                    }
                }
                """,
            findings: [
                FindingSpec(
                    "1️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
                FindingSpec(
                    "2️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
            ]
        )
    }

    @Test func preservesBooleanGuardWithInterpolatedFailMessage() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
                import XCTest

                class TestCase: XCTestCase {
                    func test_something() {
                        guard optionalValue2 == nil else {
                            XCTFail("Value was \\(String(describing: optionalValue2))")
                            return
                        }
                    }
                }
                """,
            expected: """
                import XCTest

                class TestCase: XCTestCase {
                    func test_something() {
                        guard optionalValue2 == nil else {
                            XCTFail("Value was \\(String(describing: optionalValue2))")
                            return
                        }
                    }
                }
                """,
            findings: []
        )
    }

    // MARK: - XCTest: Preserves (no change)

    @Test func doesNotReplaceNonTestFunction() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
                import XCTest

                class TestCase: XCTestCase {
                    func helper() {
                        guard let value = optionalValue else {
                            XCTFail()
                            return
                        }
                    }
                }
                """,
            expected: """
                import XCTest

                class TestCase: XCTestCase {
                    func helper() {
                        guard let value = optionalValue else {
                            XCTFail()
                            return
                        }
                    }
                }
                """,
            findings: []
        )
    }

    @Test func doesNotReplaceGuardWithDifferentElseBlock() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
                import XCTest

                class TestCase: XCTestCase {
                    func test_something() {
                        guard let value = optionalValue else {
                            print("no value")
                            return
                        }
                    }
                }
                """,
            expected: """
                import XCTest

                class TestCase: XCTestCase {
                    func test_something() {
                        guard let value = optionalValue else {
                            print("no value")
                            return
                        }
                    }
                }
                """,
            findings: []
        )
    }

    @Test func doesNotReplaceInClosure() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
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
                """,
            expected: """
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
                """,
            findings: []
        )
    }

    @Test func doesNotReplaceInNestedFunc() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
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
                """,
            expected: """
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
                """,
            findings: []
        )
    }

    @Test func noChangeWhenNontrivialGuardBody() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
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
                """,
            expected: """
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
                """,
            findings: []
        )
    }

    // MARK: - XCTest: Effect specifiers

    @Test func preservesExistingThrows() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
                import XCTest

                class TestCase: XCTestCase {
                    func test_something() throws {
                        1️⃣guard let value = optionalValue else {
                            XCTFail()
                            return
                        }
                    }
                }
                """,
            expected: """
                import XCTest

                class TestCase: XCTestCase {
                    func test_something() throws {
                        let value = try XCTUnwrap(optionalValue)
                    }
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap")
            ]
        )
    }

    @Test func handlesAsyncFunction() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
                import XCTest

                class TestCase: XCTestCase {
                    func test_something() async {
                        let optionalValue = await function()
                        1️⃣guard let value = optionalValue else {
                            XCTFail()
                            return
                        }
                    }
                }
                """,
            expected: """
                import XCTest

                class TestCase: XCTestCase {
                    func test_something() async throws {
                        let optionalValue = await function()
                        let value = try XCTUnwrap(optionalValue)
                    }
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap")
            ]
        )
    }

    // MARK: - XCTest: Variable shadowing

    @Test func doesNotReplaceWhenVariableShadowing() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
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
                """,
            expected: """
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
                """,
            findings: []
        )
    }

    @Test func doesNotReplaceWhenAnyShadowing() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
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
                """,
            expected: """
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
                """,
            findings: []
        )
    }

    @Test func handlesGuardLetShorthand() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
                import XCTest

                class TestCase: XCTestCase {
                    private var optionalValue: String?

                    func test_something() {
                        1️⃣guard let optionalValue else {
                            XCTFail()
                            return
                        }
                        print(optionalValue)
                    }
                }
                """,
            expected: """
                import XCTest

                class TestCase: XCTestCase {
                    private var optionalValue: String?

                    func test_something() throws {
                        let optionalValue = try XCTUnwrap(optionalValue)
                        print(optionalValue)
                    }
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap")
            ]
        )
    }

    // MARK: - XCTest: Type annotations

    @Test func handlesExplicitTypeAnnotation() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
                import XCTest

                class TestCase: XCTestCase {
                    func test_something() {
                        1️⃣guard var foo: Foo = getFoo() else {
                            XCTFail()
                            return
                        }
                        foo = otherFoo
                        print(foo)
                    }
                }
                """,
            expected: """
                import XCTest

                class TestCase: XCTestCase {
                    func test_something() throws {
                        var foo: Foo = try XCTUnwrap(getFoo())
                        foo = otherFoo
                        print(foo)
                    }
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap")
            ]
        )
    }

    // MARK: - XCTest: Await and pattern matching

    @Test func preservesGuardWithAwaitInCondition() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
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
                """,
            expected: """
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
                """,
            findings: []
        )
    }

    @Test func preservesGuardWithPatternMatching() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
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
                """,
            expected: """
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
                """,
            findings: []
        )
    }

    // MARK: - Swift Testing: Basic guard replacement

    @Test func swiftTestingReplaceGuardReturn() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
                import Testing

                struct SomeTests {
                    @Test
                    func something() {
                        1️⃣guard let value = optionalValue else {
                            return
                        }
                        print(value)
                    }
                }
                """,
            expected: """
                import Testing

                struct SomeTests {
                    @Test
                    func something() throws {
                        let value = try #require(optionalValue)
                        print(value)
                    }
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap")
            ]
        )
    }

    @Test func swiftTestingIssueRecordReplacement() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
                import Testing

                struct SomeTests {
                    @Test
                    func something() {
                        1️⃣guard let value = optionalValue else {
                            Issue.record()
                            return
                        }
                        print(value)
                    }
                }
                """,
            expected: """
                import Testing

                struct SomeTests {
                    @Test
                    func something() throws {
                        let value = try #require(optionalValue)
                        print(value)
                    }
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap")
            ]
        )
    }

    @Test func swiftTestingIssueRecordWithMessage() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
                import Testing

                struct SomeTests {
                    @Test
                    func something() {
                        1️⃣guard let value = optionalValue else {
                            Issue.record("Expected value to be non-nil")
                            return
                        }
                    }
                }
                """,
            expected: """
                import Testing

                struct SomeTests {
                    @Test
                    func something() throws {
                        let value = try #require(optionalValue, "Expected value to be non-nil")
                    }
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap")
            ]
        )
    }

    @Test func swiftTestingBooleanConditionBecomesRequire() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
                import Testing

                struct SomeTests {
                    @Test
                    func something() {
                        1️⃣guard let value = optionalValue,
                              someCondition else {
                            return
                        }
                    }
                }
                """,
            expected: """
                import Testing

                struct SomeTests {
                    @Test
                    func something() throws {
                        let value = try #require(optionalValue)
                        try #require(someCondition)
                    }
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap")
            ]
        )
    }

    @Test func swiftTestingBooleanOnlyGuardKeepsEarlyExit() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
                import Testing

                struct SomeTests {
                    @Test
                    func something() {
                        1️⃣guard polygons.count > 1 else {
                            return
                        }

                        let a = Set(polygons[0].vertices)
                    }
                }
                """,
            expected: """
                import Testing

                struct SomeTests {
                    @Test
                    func something() throws {
                        try #require(polygons.count > 1)

                        let a = Set(polygons[0].vertices)
                    }
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap")
            ]
        )
    }

    @Test func swiftTestingMultipleOptionalBindings() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
                import Testing

                struct SomeTests {
                    @Test
                    func something() {
                        1️⃣guard let value = optionalValue,
                              let other = otherValue else {
                            return
                        }
                    }
                }
                """,
            expected: """
                import Testing

                struct SomeTests {
                    @Test
                    func something() throws {
                        let value = try #require(optionalValue)
                        let other = try #require(otherValue)
                    }
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap")
            ]
        )
    }

    @Test func swiftTestingAsyncFunction() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
                import Testing

                struct SomeTests {
                    @Test
                    func something() async {
                        let optionalValue = await function()
                        1️⃣guard let value = optionalValue else {
                            return
                        }
                    }
                }
                """,
            expected: """
                import Testing

                struct SomeTests {
                    @Test
                    func something() async throws {
                        let optionalValue = await function()
                        let value = try #require(optionalValue)
                    }
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap")
            ]
        )
    }

    // MARK: - Swift Testing: Preserves

    @Test func swiftTestingDoesNotReplaceNonTestFunction() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
                import Testing

                struct SomeTests {
                    func helper() {
                        guard let value = optionalValue else {
                            return
                        }
                    }
                }
                """,
            expected: """
                import Testing

                struct SomeTests {
                    func helper() {
                        guard let value = optionalValue else {
                            return
                        }
                    }
                }
                """,
            findings: []
        )
    }

    @Test func swiftTestingDoesNotReplaceInClosure() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
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
                """,
            expected: """
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
                """,
            findings: []
        )
    }

    @Test func swiftTestingPreservesGuardWithAwait() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
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
                """,
            expected: """
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
                """,
            findings: []
        )
    }

    @Test func swiftTestingHandlesGuardLetShorthand() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
                import Testing

                struct SomeTests {
                    @Test
                    func something(value: String?) {
                        1️⃣guard let value else {
                            return
                        }
                        print(value)
                    }
                }
                """,
            expected: """
                import Testing

                struct SomeTests {
                    @Test
                    func something(value: String?) throws {
                        let value = try #require(value)
                        print(value)
                    }
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap")
            ]
        )
    }

    // MARK: - XCTest: Stress tests

    @Test func preservesMixedGuardWithCompactElse() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
                import XCTest

                class TestCase: XCTestCase {
                    func test_something() {
                        guard condition,
                            let value = optionalValue
                        else { XCTFail()
                            return }
                    }
                }
                """,
            expected: """
                import XCTest

                class TestCase: XCTestCase {
                    func test_something() {
                        guard condition,
                            let value = optionalValue
                        else { XCTFail()
                            return }
                    }
                }
                """,
            findings: []
        )
    }

    @Test func handlesFiveConditions() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
                import XCTest

                class TestCase: XCTestCase {
                    func test_something() {
                        1️⃣guard let value1 = optional1,
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
                """,
            expected: """
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
                """,
            findings: [
                FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap")
            ]
        )
    }

    @Test func handlesTenConditions() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
                import XCTest

                class TestCase: XCTestCase {
                    func test_something() {
                        1️⃣guard let value1 = optional1,
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
                """,
            expected: """
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
                """,
            findings: [
                FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap")
            ]
        )
    }

    @Test func preservesMixedComplexConditions() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
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
                """,
            expected: """
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
                """,
            findings: []
        )
    }

    // MARK: - XCTest: Dependent conditions

    @Test func preservesDependentConditions() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
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
                """,
            expected: """
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
                """,
            findings: []
        )
    }

    // MARK: - XCTest: Additional type annotation tests

    @Test func handlesExplicitTypeAnnotationWithShorthand() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
                import XCTest

                class TestCase: XCTestCase {
                    func test_something() {
                        1️⃣guard let foo, let bar: Bar else {
                            XCTFail()
                            return
                        }
                        print(foo, bar)
                    }
                }
                """,
            expected: """
                import XCTest

                class TestCase: XCTestCase {
                    func test_something() throws {
                        let foo = try XCTUnwrap(foo)
                        let bar: Bar = try XCTUnwrap(bar)
                        print(foo, bar)
                    }
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap")
            ]
        )
    }

    @Test func handlesComplexTypeAnnotation() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
                import XCTest

                class TestCase: XCTestCase {
                    func test_something() {
                        1️⃣guard let value: [String: Any] = getDictionary() else {
                            return
                        }
                        print(value)
                    }
                }
                """,
            expected: """
                import XCTest

                class TestCase: XCTestCase {
                    func test_something() throws {
                        let value: [String: Any] = try XCTUnwrap(getDictionary())
                        print(value)
                    }
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap")
            ]
        )
    }

    // MARK: - XCTest: Additional shadow and condition tests

    @Test func preservesGuardWithShadowedVariable() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
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
                """,
            expected: """
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
                """,
            findings: []
        )
    }

    @Test func doesNotReplaceWhenVariableShadowingWithReturn() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
                import XCTest

                class TestCase: XCTestCase {
                    func test_something() {
                        let value: String? = ""
                        guard let value else {
                            return
                        }
                    }
                }
                """,
            expected: """
                import XCTest

                class TestCase: XCTestCase {
                    func test_something() {
                        let value: String? = ""
                        guard let value else {
                            return
                        }
                    }
                }
                """,
            findings: []
        )
    }

    @Test func convertsBooleanConditionsToRequire() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
                import Testing

                struct SomeTests {
                    @Test
                    func something() {
                        1️⃣guard someCondition,
                              let value = optionalValue else {
                            return
                        }
                        print(value)
                    }
                }
                """,
            expected: """
                import Testing

                struct SomeTests {
                    @Test
                    func something() throws {
                        try #require(someCondition)
                        let value = try #require(optionalValue)
                        print(value)
                    }
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap")
            ]
        )
    }

    @Test func preservesMultipleBooleanConditions() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
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
                """,
            expected: """
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
                """,
            findings: []
        )
    }

    @Test func preservesGuardWithAwaitInMultipleConditions() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
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
                """,
            expected: """
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
                """,
            findings: []
        )
    }

    // MARK: - Swift Testing: Additional tests

    @Test func swiftTestingPreservesExistingThrows() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
                import Testing

                struct SomeTests {
                    @Test
                    func something() throws {
                        1️⃣guard let value = optionalValue else {
                            return
                        }
                    }
                }
                """,
            expected: """
                import Testing

                struct SomeTests {
                    @Test
                    func something() throws {
                        let value = try #require(optionalValue)
                    }
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap")
            ]
        )
    }

    @Test func swiftTestingMultipleGuardStatements() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
                import Testing

                struct SomeTests {
                    @Test
                    func something() {
                        1️⃣guard let value1 = optionalValue1 else {
                            return
                        }
                        2️⃣guard let value2 = optionalValue2 else {
                            return
                        }
                    }
                }
                """,
            expected: """
                import Testing

                struct SomeTests {
                    @Test
                    func something() throws {
                        let value1 = try #require(optionalValue1)
                        let value2 = try #require(optionalValue2)
                    }
                }
                """,
            findings: [
                FindingSpec(
                    "1️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
                FindingSpec(
                    "2️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
            ]
        )
    }

    @Test func swiftTestingDoesNotReplaceGuardWithDifferentElseBlock() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
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
                """,
            expected: """
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
                """,
            findings: []
        )
    }

    @Test func handlesTypeAnnotationSwiftTesting() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
                import Testing

                struct SomeTests {
                    @Test
                    func something() {
                        1️⃣guard let result: Result<String, Error> = getResult() else {
                            return
                        }
                        print(result)
                    }
                }
                """,
            expected: """
                import Testing

                struct SomeTests {
                    @Test
                    func something() throws {
                        let result: Result<String, Error> = try #require(getResult())
                        print(result)
                    }
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap")
            ]
        )
    }

    @Test func preserveFailMessage() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
                import XCTest

                class TestCase: XCTestCase {
                    func test_something() {
                        1️⃣guard let value1 = optionalValue1 else {
                            XCTFail("Failed")
                            return
                        }
                        guard optionalValue2 != nil else {
                            XCTFail("Value was nil")
                            return
                        }
                    }
                }
                """,
            expected: """
                import XCTest

                class TestCase: XCTestCase {
                    func test_something() throws {
                        let value1 = try XCTUnwrap(optionalValue1, "Failed")
                        guard optionalValue2 != nil else {
                            XCTFail("Value was nil")
                            return
                        }
                    }
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap")
            ]
        )
    }

    // MARK: - No import

    @Test func doesNothingWithoutImport() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
                func test_something() {
                    guard let value = optionalValue else {
                        return
                    }
                }
                """,
            expected: """
                func test_something() {
                    guard let value = optionalValue else {
                        return
                    }
                }
                """,
            findings: []
        )
    }

    // MARK: - Finding location

    /// Jig issue `d1f36c67`: the finding was anchored on the rewritten tree. A rewritten node
    /// detaches from the parsed file, so its offset named a line far from the `guard`. The nested
    /// `guard` here forces that detachment for the outer statement list.
    @Test func reportsTheGuardOwnLineAfterAnEarlierRewrite() {
        assertFormatting(
            NoGuardInTests.self,
            input: """
                import XCTest

                class TestCase: XCTestCase {
                    func test_something() {
                        if condition {
                            1️⃣guard let inner = optionalInner else {
                                return
                            }
                            print(inner)
                        }
                        2️⃣guard let outer = optionalOuter else {
                            return
                        }
                        print(outer)
                    }
                }
                """,
            expected: """
                import XCTest

                class TestCase: XCTestCase {
                    func test_something() throws {
                        if condition {
                            let inner = try XCTUnwrap(optionalInner)
                            print(inner)
                        }
                        let outer = try XCTUnwrap(optionalOuter)
                        print(outer)
                    }
                }
                """,
            findings: [
                FindingSpec(
                    "1️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
                FindingSpec(
                    "2️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
            ]
        )
    }
}
