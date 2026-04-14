@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoForceUnwrapInTestsTests: RuleTesting {

  // MARK: - XCTest: Simple force unwrap

  @Test func simpleForceUnwrapInXCTest() {
    assertFormatting(
      NoForceUnwrapInTests.self,
      input: """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                let result = myOptional1️⃣!.with.nested2️⃣!.property3️⃣!
            }
        }
        """,
      expected: """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                let result = try XCTUnwrap(myOptional?.with.nested?.property)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace force unwrap in test with 'XCTUnwrap' or '#require'"),
        FindingSpec("2️⃣", message: "replace force unwrap in test with 'XCTUnwrap' or '#require'"),
        FindingSpec("3️⃣", message: "replace force unwrap in test with 'XCTUnwrap' or '#require'"),
      ]
    )
  }

  @Test func simpleForceUnwrapInSwiftTesting() {
    assertFormatting(
      NoForceUnwrapInTests.self,
      input: """
        import Testing

        struct TestCase {
            @Test func something() {
                let result = myOptional1️⃣!.with.nested2️⃣!.property3️⃣!
            }
        }
        """,
      expected: """
        import Testing

        struct TestCase {
            @Test func something() throws {
                let result = try #require(myOptional?.with.nested?.property)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace force unwrap in test with 'XCTUnwrap' or '#require'"),
        FindingSpec("2️⃣", message: "replace force unwrap in test with 'XCTUnwrap' or '#require'"),
        FindingSpec("3️⃣", message: "replace force unwrap in test with 'XCTUnwrap' or '#require'"),
      ]
    )
  }

  // MARK: - XCTest: Assignment

  @Test func forceUnwrapInAssignment() {
    assertFormatting(
      NoForceUnwrapInTests.self,
      input: """
        import XCTest

        class TestCase: XCTestCase {
            func test_assignment() {
                let foo = someOptional1️⃣!
                var bar = anotherOptional2️⃣!
            }
        }
        """,
      expected: """
        import XCTest

        class TestCase: XCTestCase {
            func test_assignment() throws {
                let foo = try XCTUnwrap(someOptional)
                var bar = try XCTUnwrap(anotherOptional)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace force unwrap in test with 'XCTUnwrap' or '#require'"),
        FindingSpec("2️⃣", message: "replace force unwrap in test with 'XCTUnwrap' or '#require'"),
      ]
    )
  }

  // MARK: - XCTest: Property access

  @Test func forceUnwrapWithPropertyAccess() {
    assertFormatting(
      NoForceUnwrapInTests.self,
      input: """
        import XCTest

        class TestCase: XCTestCase {
            func test_propertyAccess() {
                let result = object1️⃣!.property2️⃣!
            }
        }
        """,
      expected: """
        import XCTest

        class TestCase: XCTestCase {
            func test_propertyAccess() throws {
                let result = try XCTUnwrap(object?.property)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace force unwrap in test with 'XCTUnwrap' or '#require'"),
        FindingSpec("2️⃣", message: "replace force unwrap in test with 'XCTUnwrap' or '#require'"),
      ]
    )
  }

  // MARK: - Assignment LHS

  @Test func forceUnwrapInAssignmentLHS() {
    assertFormatting(
      NoForceUnwrapInTests.self,
      input: """
        import XCTest

        class TestCase: XCTestCase {
            func testForceUnwrapInAssignment() {
                foo1️⃣!.bar2️⃣!.baaz = quux
            }
        }
        """,
      expected: """
        import XCTest

        class TestCase: XCTestCase {
            func testForceUnwrapInAssignment() {
                foo?.bar?.baaz = quux
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace force unwrap in test with 'XCTUnwrap' or '#require'"),
        FindingSpec("2️⃣", message: "replace force unwrap in test with 'XCTUnwrap' or '#require'"),
      ]
    )
  }

  // MARK: - Equality comparison

  @Test func equalityComparisonKeepsOptionalChaining() {
    assertFormatting(
      NoForceUnwrapInTests.self,
      input: """
        import Testing

        @Test func something() {
            #expect(foo1️⃣!.bar == baaz)
        }
        """,
      expected: """
        import Testing

        @Test func something() {
            #expect(foo?.bar == baaz)
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace force unwrap in test with 'XCTUnwrap' or '#require'"),
      ]
    )
  }

  @Test func equalityComparisonWithNil() {
    assertFormatting(
      NoForceUnwrapInTests.self,
      input: """
        import Testing

        @Test func something() {
            #expect(foo1️⃣!.bar == nil)
        }
        """,
      expected: """
        import Testing

        @Test func something() {
            #expect(foo?.bar == nil)
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace force unwrap in test with 'XCTUnwrap' or '#require'"),
      ]
    )
  }

  // MARK: - XCTAssertEqual / XCTAssertNil

  @Test func xctAssertEqualKeepsOptionalChaining() {
    assertFormatting(
      NoForceUnwrapInTests.self,
      input: """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                XCTAssertEqual(foo1️⃣!.bar, baaz2️⃣!.quux)
            }
        }
        """,
      expected: """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                XCTAssertEqual(foo?.bar, baaz?.quux)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace force unwrap in test with 'XCTUnwrap' or '#require'"),
        FindingSpec("2️⃣", message: "replace force unwrap in test with 'XCTUnwrap' or '#require'"),
      ]
    )
  }

  @Test func xctAssertNilKeepsOptionalChaining() {
    assertFormatting(
      NoForceUnwrapInTests.self,
      input: """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                XCTAssertNil(foo1️⃣!.bar)
            }
        }
        """,
      expected: """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                XCTAssertNil(foo?.bar)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace force unwrap in test with 'XCTUnwrap' or '#require'"),
      ]
    )
  }

  // MARK: - Standalone method calls

  @Test func standaloneMethodCall() {
    assertFormatting(
      NoForceUnwrapInTests.self,
      input: """
        import XCTest

        class TestCase: XCTestCase {
            func testForceUnwrappedMethodCallBase() throws {
                foo1️⃣!.prepareA()
                foo2️⃣!.prepareB()
            }
        }
        """,
      expected: """
        import XCTest

        class TestCase: XCTestCase {
            func testForceUnwrappedMethodCallBase() throws {
                foo?.prepareA()
                foo?.prepareB()
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace force unwrap in test with 'XCTUnwrap' or '#require'"),
        FindingSpec("2️⃣", message: "replace force unwrap in test with 'XCTUnwrap' or '#require'"),
      ]
    )
  }

  // MARK: - Preserves (no change)

  @Test func nonTestFunctionIsNotModified() {
    assertFormatting(
      NoForceUnwrapInTests.self,
      input: """
        import XCTest

        class TestCase: XCTestCase {
            func something() {
                let result = myOptional!
            }
        }
        """,
      expected: """
        import XCTest

        class TestCase: XCTestCase {
            func something() {
                let result = myOptional!
            }
        }
        """,
      findings: []
    )
  }

  @Test func forceUnwrapInStringInterpolationIsNotModified() {
    assertFormatting(
      NoForceUnwrapInTests.self,
      input: """
        import XCTest

        class TestCase: XCTestCase {
            func test_closure() {
                print("foo \\(bar!)")
            }
        }
        """,
      expected: """
        import XCTest

        class TestCase: XCTestCase {
            func test_closure() {
                print("foo \\(bar!)")
            }
        }
        """,
      findings: []
    )
  }

  @Test func forceUnwrapInNestedFunctionIsNotModified() {
    assertFormatting(
      NoForceUnwrapInTests.self,
      input: """
        import XCTest

        class TestCase: XCTestCase {
            func test_nestedFunction() {
                func helper() {
                    let result = myOptional!
                }
            }
        }
        """,
      expected: """
        import XCTest

        class TestCase: XCTestCase {
            func test_nestedFunction() {
                func helper() {
                    let result = myOptional!
                }
            }
        }
        """,
      findings: []
    )
  }

  // MARK: - Already throwing

  @Test func alreadyThrowingFunction() {
    assertFormatting(
      NoForceUnwrapInTests.self,
      input: """
        import XCTest

        class TestCase: XCTestCase {
            func test_alreadyThrowing() throws {
                let result = myOptional1️⃣!
            }
        }
        """,
      expected: """
        import XCTest

        class TestCase: XCTestCase {
            func test_alreadyThrowing() throws {
                let result = try XCTUnwrap(myOptional)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace force unwrap in test with 'XCTUnwrap' or '#require'"),
      ]
    )
  }

  @Test func asyncThrowingFunction() {
    assertFormatting(
      NoForceUnwrapInTests.self,
      input: """
        import Testing

        struct TestCase {
            @Test func asyncTest() async {
                let myOptional = await function()
                let result = myOptional1️⃣!
            }
        }
        """,
      expected: """
        import Testing

        struct TestCase {
            @Test func asyncTest() async throws {
                let myOptional = await function()
                let result = try #require(myOptional)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace force unwrap in test with 'XCTUnwrap' or '#require'"),
      ]
    )
  }

  // MARK: - Force cast (as!)

  @Test func simpleForceCast() {
    assertFormatting(
      NoForceUnwrapInTests.self,
      input: """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                let result = fooBar(foo 1️⃣as! Foo)
            }
        }
        """,
      expected: """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                let result = fooBar(try XCTUnwrap(foo as? Foo))
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace force cast in test with optional cast"),
      ]
    )
  }

  // MARK: - IUO type annotations

  @Test func implicitlyUnwrappedOptionalTypesAreNotModified() {
    assertFormatting(
      NoForceUnwrapInTests.self,
      input: """
        import XCTest

        class TestCase: XCTestCase {
            func test_implicitlyUnwrappedOptionals() {
                let foo: String! = "test"
                var bar: Int! = 42
                let result = foo1️⃣! + "suffix"
            }
        }
        """,
      expected: """
        import XCTest

        class TestCase: XCTestCase {
            func test_implicitlyUnwrappedOptionals() throws {
                let foo: String! = "test"
                var bar: Int! = 42
                let result = try XCTUnwrap(foo) + "suffix"
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace force unwrap in test with 'XCTUnwrap' or '#require'"),
      ]
    )
  }

  // MARK: - No import

  @Test func noImportDoesNothing() {
    assertFormatting(
      NoForceUnwrapInTests.self,
      input: """
        func test_something() {
            let result = myOptional!
        }
        """,
      expected: """
        func test_something() {
            let result = myOptional!
        }
        """,
      findings: []
    )
  }
}
