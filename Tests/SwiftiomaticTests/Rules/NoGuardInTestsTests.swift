@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

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
        FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
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
        FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
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
        FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
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
        FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
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
        FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
      ]
    )
  }

  @Test func booleanConditionConvertsToAssert() {
    assertFormatting(
      NoGuardInTests.self,
      input: """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                1️⃣guard someCondition,
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
            func test_something() throws {
                XCTAssert(someCondition)
                let value = try XCTUnwrap(optionalValue)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
      ]
    )
  }

  @Test func mixedConditions() {
    assertFormatting(
      NoGuardInTests.self,
      input: """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                1️⃣guard let value = optionalValue,
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
            func test_something() throws {
                let value = try XCTUnwrap(optionalValue)
                XCTAssert(someCondition)
                let other = try XCTUnwrap(otherValue)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
      ]
    )
  }

  @Test func nonUnwrapConditionsDontInsertThrows() {
    assertFormatting(
      NoGuardInTests.self,
      input: """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                1️⃣guard condition, optionalValue != nil else {
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
                XCTAssert(condition)
                XCTAssert(optionalValue != nil)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
      ]
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
        FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
        FindingSpec("2️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
      ]
    )
  }

  @Test func preserveFailMessageWithInterpolation() {
    assertFormatting(
      NoGuardInTests.self,
      input: """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                1️⃣guard optionalValue2 == nil else {
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
                XCTAssert(optionalValue2 == nil, "Value was \\(String(describing: optionalValue2))")
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
      ]
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
        FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
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
        FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
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
        FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
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
        FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
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
        FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
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
        FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
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
        FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
      ]
    )
  }

  @Test func swiftTestingMultipleConditionsWithExpect() {
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
                #expect(someCondition)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
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
        FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
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
        FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
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
        FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
      ]
    )
  }

  // MARK: - XCTest: Stress tests

  @Test func simpleMultipleConditionsCompactElse() {
    assertFormatting(
      NoGuardInTests.self,
      input: """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                1️⃣guard condition,
                    let value = optionalValue
                else { XCTFail()
                    return }
            }
        }
        """,
      expected: """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                XCTAssert(condition)
                let value = try XCTUnwrap(optionalValue)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
      ]
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
        FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
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
        FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
      ]
    )
  }

  @Test func handlesMixedComplexConditions() {
    assertFormatting(
      NoGuardInTests.self,
      input: """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                1️⃣guard condition1,
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
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
      ]
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
        FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
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
        FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
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

  @Test func convertsBooleanConditionsToExpect() {
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
                #expect(someCondition)
                let value = try #require(optionalValue)
                print(value)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
      ]
    )
  }

  @Test func convertsMultipleBooleanConditions() {
    assertFormatting(
      NoGuardInTests.self,
      input: """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                1️⃣guard condition1,
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
            func test_something() throws {
                XCTAssert(condition1)
                XCTAssert(condition2)
                let value = try XCTUnwrap(optionalValue)
                XCTAssert(condition3)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
      ]
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
        FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
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
        FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
        FindingSpec("2️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
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
        FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
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
                2️⃣guard optionalValue2 != nil else {
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
                XCTAssert(optionalValue2 != nil, "Value was nil")
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
        FindingSpec("2️⃣", message: "replace 'guard' in test with direct assertion or unwrap"),
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
}
