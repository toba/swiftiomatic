@testable import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoForceUnwrapTests: RuleTesting {

  // MARK: - Non-test code: diagnose only

  @Test func unsafeUnwrap() {
    assertFormatting(
      NoForceUnwrap.self,
      input: """
        func someFunc() -> Int {
          var a = getInt()
          var b = 1️⃣a as! Int
          let c = 2️⃣(someValue())!
          let d = 3️⃣String(a)!
          let regex = try! NSRegularExpression(pattern: "a*b+c?")
          let e = /*comment about stuff*/ 4️⃣[1: a, 2: b, 3: c][4]!
          var f = 5️⃣a as! /*comment about this type*/ FooBarType
          return 6️⃣a!
        }
        """,
      expected: """
        func someFunc() -> Int {
          var a = getInt()
          var b = a as! Int
          let c = (someValue())!
          let d = String(a)!
          let regex = try! NSRegularExpression(pattern: "a*b+c?")
          let e = /*comment about stuff*/ [1: a, 2: b, 3: c][4]!
          var f = a as! /*comment about this type*/ FooBarType
          return a!
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "do not force cast to 'Int'"),
        FindingSpec("2️⃣", message: "do not force unwrap '(someValue())'"),
        FindingSpec("3️⃣", message: "do not force unwrap 'String(a)'"),
        FindingSpec("4️⃣", message: "do not force unwrap '[1: a, 2: b, 3: c][4]'"),
        FindingSpec("5️⃣", message: "do not force cast to 'FooBarType'"),
        FindingSpec("6️⃣", message: "do not force unwrap 'a'"),
      ]
    )
  }

  @Test func noImportDoesNothing() {
    assertFormatting(
      NoForceUnwrap.self,
      input: """
        func test_something() {
            let result = 1️⃣myOptional!
        }
        """,
      expected: """
        func test_something() {
            let result = myOptional!
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "do not force unwrap 'myOptional'"),
      ]
    )
  }

  // MARK: - XCTest: Simple force unwrap

  @Test func simpleForceUnwrapInXCTest() {
    assertFormatting(
      NoForceUnwrap.self,
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
      NoForceUnwrap.self,
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
      NoForceUnwrap.self,
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
      NoForceUnwrap.self,
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
      NoForceUnwrap.self,
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
      NoForceUnwrap.self,
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
      NoForceUnwrap.self,
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
      NoForceUnwrap.self,
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
      NoForceUnwrap.self,
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
      NoForceUnwrap.self,
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
      NoForceUnwrap.self,
      input: """
        import XCTest

        class TestCase: XCTestCase {
            func something() {
                let result = 1️⃣myOptional!
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
      findings: [
        FindingSpec("1️⃣", message: "do not force unwrap 'myOptional'"),
      ]
    )
  }

  @Test func forceUnwrapInStringInterpolationIsNotModified() {
    assertFormatting(
      NoForceUnwrap.self,
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
      NoForceUnwrap.self,
      input: """
        import XCTest

        class TestCase: XCTestCase {
            func test_nestedFunction() {
                func helper() {
                    let result = 1️⃣myOptional!
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
      findings: [
        FindingSpec("1️⃣", message: "do not force unwrap 'myOptional'"),
      ]
    )
  }

  // MARK: - Already throwing

  @Test func alreadyThrowingFunction() {
    assertFormatting(
      NoForceUnwrap.self,
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
      NoForceUnwrap.self,
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
      NoForceUnwrap.self,
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
      NoForceUnwrap.self,
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

  // MARK: - Function call arguments

  @Test func forceUnwrapInFunctionCallArguments() {
    assertFormatting(
      NoForceUnwrap.self,
      input: """
        import XCTest

        class TestCase: XCTestCase {
            func test_functionCall() {
                someFunction(myOptional1️⃣!, anotherOptional2️⃣!)
            }
        }
        """,
      expected: """
        import XCTest

        class TestCase: XCTestCase {
            func test_functionCall() throws {
                someFunction(try XCTUnwrap(myOptional), try XCTUnwrap(anotherOptional))
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace force unwrap in test with 'XCTUnwrap' or '#require'"),
        FindingSpec("2️⃣", message: "replace force unwrap in test with 'XCTUnwrap' or '#require'"),
      ]
    )
  }

  // MARK: - XCTAssertEqual with accuracy (3 args — requires wrapping)

  @Test func xctAssertEqualWithAccuracyRequiresUnwrap() {
    assertFormatting(
      NoForceUnwrap.self,
      input: """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                XCTAssertEqual(foo1️⃣!.value, 3.14, accuracy: 0.01)
            }
        }
        """,
      expected: """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                XCTAssertEqual(try XCTUnwrap(foo?.value), 3.14, accuracy: 0.01)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace force unwrap in test with 'XCTUnwrap' or '#require'"),
      ]
    )
  }

  // MARK: - Return statement

  @Test func forceUnwrapInReturnStatement() {
    assertFormatting(
      NoForceUnwrap.self,
      input: """
        import XCTest

        class TestCase: XCTestCase {
            func test_return() {
                return myOptional1️⃣!.array2️⃣!.first(where: { foo.bar == baaz })
            }
        }
        """,
      expected: """
        import XCTest

        class TestCase: XCTestCase {
            func test_return() throws {
                return try XCTUnwrap(myOptional?.array?.first(where: { foo.bar == baaz }))
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace force unwrap in test with 'XCTUnwrap' or '#require'"),
        FindingSpec("2️⃣", message: "replace force unwrap in test with 'XCTUnwrap' or '#require'"),
      ]
    )
  }

  // MARK: - Closure is not modified

  @Test func forceUnwrapInClosureIsNotModified() {
    assertFormatting(
      NoForceUnwrap.self,
      input: """
        import XCTest

        class TestCase: XCTestCase {
            func testReturnValue() -> Bool {
                1️⃣foo!.bar!
            }

            func notATest() {
                print(foo!.bar!)
            }
        }
        """,
      expected: """
        import XCTest

        class TestCase: XCTestCase {
            func testReturnValue() -> Bool {
                foo!.bar!
            }

            func notATest() {
                print(foo!.bar!)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "do not force unwrap 'foo!.bar'"),
      ]
    )
  }

  // MARK: - Test helper is not updated

  @Test func testHelperIsNotUpdated() {
    assertFormatting(
      NoForceUnwrap.self,
      input: """
        import XCTest

        class TestCase: XCTestCase {
            func test_helper(arg: Bool) {
                let result = 1️⃣myOptional!.with.nested!.property! && arg
            }
        }
        """,
      expected: """
        import XCTest

        class TestCase: XCTestCase {
            func test_helper(arg: Bool) {
                let result = myOptional!.with.nested!.property! && arg
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "do not force unwrap 'myOptional!.with.nested!.property'"),
      ]
    )
  }

  // MARK: - Swift Testing with multiple attributes

  @Test func swiftTestingWithMultipleAttributes() {
    assertFormatting(
      NoForceUnwrap.self,
      input: """
        import Testing

        struct TestCase {
            @Test
            @available(iOS 14.0, *)
            func multipleAttributes() {
                let result = myOptional1️⃣!
            }
        }
        """,
      expected: """
        import Testing

        struct TestCase {
            @Test
            @available(iOS 14.0, *)
            func multipleAttributes() throws {
                let result = try #require(myOptional)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace force unwrap in test with 'XCTUnwrap' or '#require'"),
      ]
    )
  }

  // MARK: - Force cast in XCTAssertEqual

  @Test func forceCastInXCTAssertEqual() {
    assertFormatting(
      NoForceUnwrap.self,
      input: """
        import XCTest

        class TestCase: XCTestCase {
            func test_forceCasts() {
                XCTAssertEqual(route.query 1️⃣as! [String: String], ["a": "b"])
            }
        }
        """,
      expected: """
        import XCTest

        class TestCase: XCTestCase {
            func test_forceCasts() {
                XCTAssertEqual(route.query as? [String: String], ["a": "b"])
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace force cast in test with optional cast"),
      ]
    )
  }

  // MARK: - Ignore test code (XCTest import — non-test functions)

  @Test func ignoreTestCode() {
    assertFormatting(
      NoForceUnwrap.self,
      input: """
        import XCTest

        var b = 1️⃣a as! Int
        """,
      expected: """
        import XCTest

        var b = a as! Int
        """,
      findings: [
        FindingSpec("1️⃣", message: "do not force cast to 'Int'"),
      ]
    )
  }

  // MARK: - Ignore @Test attribute function (non-test file)

  @Test func ignoreTestAttributeFunction() {
    assertFormatting(
      NoForceUnwrap.self,
      input: """
        import Testing

        @Test func someFunc() {
          var b = a1️⃣!
        }
        @Test func anotherFunc() {
          func nestedFunc() {
            let c = 2️⃣someValue()!
          }
        }
        """,
      expected: """
        import Testing

        @Test func someFunc() throws {
          var b = try #require(a)
        }
        @Test func anotherFunc() {
          func nestedFunc() {
            let c = someValue()!
          }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace force unwrap in test with 'XCTUnwrap' or '#require'"),
        FindingSpec("2️⃣", message: "do not force unwrap 'someValue()'"),
      ]
    )
  }
}
