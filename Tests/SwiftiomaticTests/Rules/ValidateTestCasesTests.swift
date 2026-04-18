@testable import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct ValidateTestCasesTests: RuleTesting {

  // MARK: - XCTest

  @Test func xcTestMethodsGetTestPrefix() {
    assertFormatting(
      ValidateTestCases.self,
      input: """
        import XCTest

        final class MyTests: XCTestCase {
            func 1️⃣example() {
                XCTAssertTrue(true)
            }
        }
        """,
      expected: """
        import XCTest

        final class MyTests: XCTestCase {
            func testExample() {
                XCTAssertTrue(true)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "add 'test' prefix to test function 'example'"),
      ]
    )
  }

  @Test func xcTestDoesNotAddPrefixToReferencedMethods() {
    assertFormatting(
      ValidateTestCases.self,
      input: """
        import XCTest

        final class MyTests: XCTestCase {
            func testMain() {
                helperMethod()
            }

            func helperMethod() {
            }
        }
        """,
      expected: """
        import XCTest

        final class MyTests: XCTestCase {
            func testMain() {
                helperMethod()
            }

            func helperMethod() {
            }
        }
        """,
      findings: []
    )
  }

  @Test func xcTestPreservesOverrideMethods() {
    assertFormatting(
      ValidateTestCases.self,
      input: """
        import XCTest

        final class MyTests: XCTestCase {
            override func setUp() {
                super.setUp()
            }

            func testExample() {
                XCTAssertTrue(true)
            }
        }
        """,
      expected: """
        import XCTest

        final class MyTests: XCTestCase {
            override func setUp() {
                super.setUp()
            }

            func testExample() {
                XCTAssertTrue(true)
            }
        }
        """,
      findings: []
    )
  }

  @Test func xcTestPreservesObjcMethods() {
    assertFormatting(
      ValidateTestCases.self,
      input: """
        import XCTest

        final class MyTests: XCTestCase {
            @objc func helperMethod() {
            }

            func testExample() {
                XCTAssertTrue(true)
            }
        }
        """,
      expected: """
        import XCTest

        final class MyTests: XCTestCase {
            @objc func helperMethod() {
            }

            func testExample() {
                XCTAssertTrue(true)
            }
        }
        """,
      findings: []
    )
  }

  @Test func xcTestHelperWithReturnTypeNotChanged() {
    assertFormatting(
      ValidateTestCases.self,
      input: """
        import XCTest

        final class MyTests: XCTestCase {
            func testHelper() -> String {
                "fixture"
            }

            func helperWithParams(arg: Bool) {
            }
        }
        """,
      expected: """
        import XCTest

        final class MyTests: XCTestCase {
            func testHelper() -> String {
                "fixture"
            }

            func helperWithParams(arg: Bool) {
            }
        }
        """,
      findings: []
    )
  }

  @Test func xcTestPreservesPrivateFunctions() {
    assertFormatting(
      ValidateTestCases.self,
      input: """
        import XCTest

        final class MyTests: XCTestCase {
            func testExample() {
                XCTAssertTrue(true)
            }

            private func helperMethod() {
            }
        }
        """,
      expected: """
        import XCTest

        final class MyTests: XCTestCase {
            func testExample() {
                XCTAssertTrue(true)
            }

            private func helperMethod() {
            }
        }
        """,
      findings: []
    )
  }

  @Test func xcTestPreservesDisabledPrefixes() {
    assertFormatting(
      ValidateTestCases.self,
      input: """
        import XCTest

        final class MyTests: XCTestCase {
            func disable_example() {
                XCTAssertTrue(true)
            }

            func skip_thisTest() {
                XCTAssertTrue(true)
            }

            func x_broken() {
                XCTAssertTrue(true)
            }

            func testEnabled() {
                XCTAssertTrue(true)
            }
        }
        """,
      expected: """
        import XCTest

        final class MyTests: XCTestCase {
            func disable_example() {
                XCTAssertTrue(true)
            }

            func skip_thisTest() {
                XCTAssertTrue(true)
            }

            func x_broken() {
                XCTAssertTrue(true)
            }

            func testEnabled() {
                XCTAssertTrue(true)
            }
        }
        """,
      findings: []
    )
  }

  @Test func xcTestDoesNotApplyWithOtherConformances() {
    assertFormatting(
      ValidateTestCases.self,
      input: """
        import XCTest

        final class MyTests: XCTestCase, SomeProtocol {
            func example() {
                XCTAssertTrue(true)
            }
        }
        """,
      expected: """
        import XCTest

        final class MyTests: XCTestCase, SomeProtocol {
            func example() {
                XCTAssertTrue(true)
            }
        }
        """,
      findings: []
    )
  }

  // MARK: - Swift Testing

  @Test func swiftTestingMethodsGetTestAttribute() {
    assertFormatting(
      ValidateTestCases.self,
      input: """
        import Testing

        struct MyFeatureTests {
            1️⃣func featureWorks() {
                #expect(true)
            }
        }
        """,
      expected: """
        import Testing

        struct MyFeatureTests {
            @Test func featureWorks() {
                #expect(true)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "add '@Test' attribute to test function"),
      ]
    )
  }

  @Test func swiftTestingPreservesPrivateFunctions() {
    assertFormatting(
      ValidateTestCases.self,
      input: """
        import Testing

        struct MyFeatureTests {
            @Test func featureWorks() {
                #expect(true)
            }

            private func helperMethod() {
            }
        }
        """,
      expected: """
        import Testing

        struct MyFeatureTests {
            @Test func featureWorks() {
                #expect(true)
            }

            private func helperMethod() {
            }
        }
        """,
      findings: []
    )
  }

  @Test func swiftTestingPreservesDisabledPrefixes() {
    assertFormatting(
      ValidateTestCases.self,
      input: """
        import Testing

        struct MyFeatureTests {
            func disable_example() {
                #expect(true)
            }

            func _temporarilyDisabled() {
                #expect(true)
            }

            1️⃣func enabled() {
                #expect(true)
            }
        }
        """,
      expected: """
        import Testing

        struct MyFeatureTests {
            func disable_example() {
                #expect(true)
            }

            func _temporarilyDisabled() {
                #expect(true)
            }

            @Test func enabled() {
                #expect(true)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "add '@Test' attribute to test function"),
      ]
    )
  }

  @Test func swiftTestingDoesNotApplyToNonTestTypes() {
    assertFormatting(
      ValidateTestCases.self,
      input: """
        import Testing

        struct TestHelpers {
            func createFixture() -> String {
                "fixture"
            }

            func setup(with data: Data) {
            }
        }
        """,
      expected: """
        import Testing

        struct TestHelpers {
            func createFixture() -> String {
                "fixture"
            }

            func setup(with data: Data) {
            }
        }
        """,
      findings: []
    )
  }

  @Test func swiftTestingStructWithTestsSuffix() {
    assertFormatting(
      ValidateTestCases.self,
      input: """
        import Testing

        struct FeatureTests {
            1️⃣func example() {
                #expect(true)
            }
        }
        """,
      expected: """
        import Testing

        struct FeatureTests {
            @Test func example() {
                #expect(true)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "add '@Test' attribute to test function"),
      ]
    )
  }

  @Test func doesNotApplyWhenBothFrameworksImported() {
    assertFormatting(
      ValidateTestCases.self,
      input: """
        import Testing
        import XCTest

        final class MyTests: XCTestCase {
            func example() {
                XCTAssertTrue(true)
            }
        }
        """,
      expected: """
        import Testing
        import XCTest

        final class MyTests: XCTestCase {
            func example() {
                XCTAssertTrue(true)
            }
        }
        """,
      findings: []
    )
  }

  @Test func doesNotApplyToBaseClasses() {
    assertFormatting(
      ValidateTestCases.self,
      input: """
        import XCTest

        open class MyFeatureTestsBase: XCTestCase {
            func example() {
                XCTAssertTrue(true)
            }
        }
        """,
      expected: """
        import XCTest

        open class MyFeatureTestsBase: XCTestCase {
            func example() {
                XCTAssertTrue(true)
            }
        }
        """,
      findings: []
    )
  }

  @Test func doesNotApplyToTypesWithParameterizedInit() {
    assertFormatting(
      ValidateTestCases.self,
      input: """
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
        """,
      expected: """
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
        """,
      findings: []
    )
  }
}
