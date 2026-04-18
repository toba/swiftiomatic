@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct PreferSwiftTestingTests: RuleTesting {

  // MARK: - Diagnostic: import only

  @Test func noXCTestImportDoesNothing() {
    assertFormatting(
      PreferSwiftTesting.self,
      input: """
        import Foundation

        func foo() {}
        """,
      expected: """
        import Foundation

        func foo() {}
        """,
      findings: []
    )
  }

  @Test func importOnly() {
    assertFormatting(
      PreferSwiftTesting.self,
      input: """
        import XCTest

        final class Tests: XCTestCase {
            func testWorks() {
            }
        }
        """,
      expected: """
        import Testing

        final class Tests {
            @Test func testWorks() {
            }
        }
        """,
      findings: []
    )
  }

  // MARK: - Minimal

  @Test func minimalConversion() {
    assertFormatting(
      PreferSwiftTesting.self,
      input: """
        import XCTest

        final class Tests: XCTestCase {
            func testWorks() {
                1️⃣XCTAssert(true)
            }
        }
        """,
      expected: """
        import Testing

        final class Tests {
            @Test func testWorks() {
                #expect(true)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "convert XCTest assertion to Swift Testing"),
      ]
    )
  }

  // MARK: - Simple conversion

  @Test func convertsSimpleTestSuite() {
    assertFormatting(
      PreferSwiftTesting.self,
      input: """
        import XCTest

        final class MyFeatureTests: XCTestCase {
            func testMyFeatureWorks() {
                let myFeature = MyFeature()
                myFeature.runAction()
                1️⃣XCTAssertTrue(myFeature.worksProperly)
                2️⃣XCTAssertEqual(myFeature.screens.count, 8)
            }
        }
        """,
      expected: """
        import Testing

        final class MyFeatureTests {
            @Test func testMyFeatureWorks() {
                let myFeature = MyFeature()
                myFeature.runAction()
                #expect(myFeature.worksProperly)
                #expect(myFeature.screens.count == 8)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "convert XCTest assertion to Swift Testing"),
        FindingSpec("2️⃣", message: "convert XCTest assertion to Swift Testing"),
      ]
    )
  }

  // MARK: - Assertion conversions

  @Test func convertsBasicAssertions() {
    assertFormatting(
      PreferSwiftTesting.self,
      input: """
        import XCTest

        class Tests: XCTestCase {
            func testAssertions() {
                1️⃣XCTAssert(foo)
                2️⃣XCTAssertTrue(foo)
                3️⃣XCTAssertFalse(foo)
                4️⃣XCTAssertNil(foo)
                5️⃣XCTAssertNotNil(foo)
                6️⃣XCTAssertEqual(foo, bar)
                7️⃣XCTAssertNotEqual(foo, bar)
                8️⃣XCTFail()
                9️⃣XCTFail("Unexpected issue")
            }
        }
        """,
      expected: """
        import Testing

        class Tests {
            @Test func testAssertions() {
                #expect(foo)
                #expect(foo)
                #expect(!foo)
                #expect(foo == nil)
                #expect(foo != nil)
                #expect(foo == bar)
                #expect(foo != bar)
                Issue.record()
                Issue.record("Unexpected issue")
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "convert XCTest assertion to Swift Testing"),
        FindingSpec("2️⃣", message: "convert XCTest assertion to Swift Testing"),
        FindingSpec("3️⃣", message: "convert XCTest assertion to Swift Testing"),
        FindingSpec("4️⃣", message: "convert XCTest assertion to Swift Testing"),
        FindingSpec("5️⃣", message: "convert XCTest assertion to Swift Testing"),
        FindingSpec("6️⃣", message: "convert XCTest assertion to Swift Testing"),
        FindingSpec("7️⃣", message: "convert XCTest assertion to Swift Testing"),
        FindingSpec("8️⃣", message: "convert XCTest assertion to Swift Testing"),
        FindingSpec("9️⃣", message: "convert XCTest assertion to Swift Testing"),
      ]
    )
  }

  @Test func convertsAssertionsWithMessages() {
    assertFormatting(
      PreferSwiftTesting.self,
      input: """
        import XCTest

        class Tests: XCTestCase {
            func testMessages() {
                1️⃣XCTAssert(foo, "foo is true")
                2️⃣XCTAssertFalse(foo, "foo is false")
                3️⃣XCTAssertNil(foo, "foo is nil")
                4️⃣XCTAssertEqual(foo, bar, "foo and bar are equal")
            }
        }
        """,
      expected: """
        import Testing

        class Tests {
            @Test func testMessages() {
                #expect(foo, "foo is true")
                #expect(!foo, "foo is false")
                #expect(foo == nil, "foo is nil")
                #expect(foo == bar, "foo and bar are equal")
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "convert XCTest assertion to Swift Testing"),
        FindingSpec("2️⃣", message: "convert XCTest assertion to Swift Testing"),
        FindingSpec("3️⃣", message: "convert XCTest assertion to Swift Testing"),
        FindingSpec("4️⃣", message: "convert XCTest assertion to Swift Testing"),
      ]
    )
  }

  @Test func convertsXCTUnwrap() {
    assertFormatting(
      PreferSwiftTesting.self,
      input: """
        import XCTest

        class Tests: XCTestCase {
            func testUnwrap() throws {
                let value = try 1️⃣XCTUnwrap(foo)
                let other = try 2️⃣XCTUnwrap(bar, "bar should not be nil")
            }
        }
        """,
      expected: """
        import Testing

        class Tests {
            @Test func testUnwrap() throws {
                let value = try #require(foo)
                let other = try #require(bar, "bar should not be nil")
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "convert XCTest assertion to Swift Testing"),
        FindingSpec("2️⃣", message: "convert XCTest assertion to Swift Testing"),
      ]
    )
  }

  // MARK: - setUp/tearDown conversion

  @Test func convertsSimpleSetUp() {
    // setUp without super call, no assertions — isolate init conversion
    assertFormatting(
      PreferSwiftTesting.self,
      input: """
        import XCTest

        final class Tests: XCTestCase {
            override func setUp() {
                f = F()
            }
        }
        """,
      expected: """
        import Testing

        final class Tests {
            init() {
                f = F()
            }
        }
        """,
      findings: []
    )
  }

  @Test func convertsSimpleTearDown() {
    assertFormatting(
      PreferSwiftTesting.self,
      input: """
        import XCTest

        final class Tests: XCTestCase {
            override func tearDown() {
                super.tearDown()
                f = nil
            }

            func testWorks() {
                1️⃣XCTAssert(true)
            }
        }
        """,
      expected: """
        import Testing

        final class Tests {
            deinit {
                f = nil
            }

            @Test func testWorks() {
                #expect(true)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "convert XCTest assertion to Swift Testing"),
      ]
    )
  }

  @Test func convertsAsyncThrowsSetUp() {
    assertFormatting(
      PreferSwiftTesting.self,
      input: """
        import XCTest

        final class Tests: XCTestCase {
            var myFeature: MyFeature!

            override func setUp() async throws {
                try await super.setUp()
                myFeature = try await MyFeature()
            }

            func testWorks() {
                1️⃣XCTAssertTrue(myFeature.works)
            }
        }
        """,
      expected: """
        import Testing

        final class Tests {
            var myFeature: MyFeature!

            init() async throws {
                myFeature = try await MyFeature()
            }

            @Test func testWorks() {
                #expect(myFeature.works)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "convert XCTest assertion to Swift Testing"),
      ]
    )
  }

  // MARK: - throws addition

  @Test func addsThrowsIfNeeded() {
    assertFormatting(
      PreferSwiftTesting.self,
      input: """
        import XCTest

        final class Tests: XCTestCase {
            func testWorks() {
                1️⃣XCTAssertTrue(try feature.worksProperly)
            }
        }
        """,
      expected: """
        import Testing

        final class Tests {
            @Test func testWorks() throws {
                #expect(try feature.worksProperly)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "convert XCTest assertion to Swift Testing"),
      ]
    )
  }

  // MARK: - Preserves (no change)

  @Test func preservesUnsupportedExpectationHelpers() {
    assertFormatting(
      PreferSwiftTesting.self,
      input: """
        import XCTest

        final class Tests: XCTestCase {
            func testAsync() {
                let expectation = expectation(description: "my feature runs async")
                MyFeature().run {
                    expectation.fulfill()
                }
                wait(for: [expectation])
            }
        }
        """,
      expected: """
        import XCTest

        final class Tests: XCTestCase {
            func testAsync() {
                let expectation = expectation(description: "my feature runs async")
                MyFeature().run {
                    expectation.fulfill()
                }
                wait(for: [expectation])
            }
        }
        """,
      findings: []
    )
  }

  @Test func preservesPerformanceTests() {
    assertFormatting(
      PreferSwiftTesting.self,
      input: """
        import XCTest

        final class Tests: XCTestCase {
            func testPerformance() {
                measure {
                    MyFeature.expensiveOperation()
                }
            }
        }
        """,
      expected: """
        import XCTest

        final class Tests: XCTestCase {
            func testPerformance() {
                measure {
                    MyFeature.expensiveOperation()
                }
            }
        }
        """,
      findings: []
    )
  }

  @Test func preservesAsyncThrowsTearDown() {
    assertFormatting(
      PreferSwiftTesting.self,
      input: """
        import XCTest

        final class Tests: XCTestCase {
            override func tearDown() async throws {
                super.tearDown()
                try await cleanup()
            }

            func testWorks() {
                XCTAssertTrue(true)
            }
        }
        """,
      expected: """
        import XCTest

        final class Tests: XCTestCase {
            override func tearDown() async throws {
                super.tearDown()
                try await cleanup()
            }

            func testWorks() {
                XCTAssertTrue(true)
            }
        }
        """,
      findings: []
    )
  }

  @Test func preservesUnsupportedMethodOverride() {
    assertFormatting(
      PreferSwiftTesting.self,
      input: """
        import XCTest

        final class Tests: XCTestCase {
            func testWorks() {
                XCTAssertTrue(true)
            }

            override func someUnknownOverride() {
                super.someUnknownOverride()
            }
        }
        """,
      expected: """
        import XCTest

        final class Tests: XCTestCase {
            func testWorks() {
                XCTAssertTrue(true)
            }

            override func someUnknownOverride() {
                super.someUnknownOverride()
            }
        }
        """,
      findings: []
    )
  }

  @Test func preservesWithoutXCTestImport() {
    assertFormatting(
      PreferSwiftTesting.self,
      input: """
        import Testing

        struct Tests {
            @Test func works() {
                #expect(true)
            }
        }
        """,
      expected: """
        import Testing

        struct Tests {
            @Test func works() {
                #expect(true)
            }
        }
        """,
      findings: []
    )
  }

  // MARK: - Test methods with arguments preserved

  @Test func preservesTestMethodWithArguments() {
    assertFormatting(
      PreferSwiftTesting.self,
      input: """
        import XCTest

        final class Tests: XCTestCase {
            func testWorks() {
                testWorks(MyFeature())
            }

            private func testWorks(_ feature: Feature) {
                feature.runAction()
                1️⃣XCTAssertTrue(feature.worksProperly)
            }
        }
        """,
      expected: """
        import Testing

        final class Tests {
            @Test func testWorks() {
                testWorks(MyFeature())
            }

            private func testWorks(_ feature: Feature) {
                feature.runAction()
                #expect(feature.worksProperly)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "convert XCTest assertion to Swift Testing"),
      ]
    )
  }

  // MARK: - Extension conversion

  @Test func convertsTestCaseExtension() {
    assertFormatting(
      PreferSwiftTesting.self,
      input: """
        import XCTest

        final class Tests: XCTestCase {
            func testWorks() {
                1️⃣XCTAssertTrue(true)
            }
        }

        extension Tests {
            func testMore() {
                2️⃣XCTAssertFalse(false)
            }
        }
        """,
      expected: """
        import Testing

        final class Tests {
            @Test func testWorks() {
                #expect(true)
            }
        }

        extension Tests {
            @Test func testMore() {
                #expect(!false)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "convert XCTest assertion to Swift Testing"),
        FindingSpec("2️⃣", message: "convert XCTest assertion to Swift Testing"),
      ]
    )
  }
}
