@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct RequireSuiteAccessControlTests: RuleTesting {

  // MARK: - XCTest

  @Test func xcTestPublicTestMethodMadeInternal() {
    assertFormatting(
      RequireSuiteAccessControl.self,
      input: """
        import XCTest

        final class MyTests: XCTestCase {
            1️⃣public func testExample() {
                XCTAssertTrue(true)
            }

            private func testHelper() {
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

            private func testHelper() {
                XCTAssertTrue(true)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove explicit access control from test method"),
      ]
    )
  }

  @Test func xcTestHelperMethodsMadePrivate() {
    assertFormatting(
      RequireSuiteAccessControl.self,
      input: """
        import XCTest

        final class MyTests: XCTestCase {
            func testExample() {
                helperMethod(arg: 0)
            }

            1️⃣func helperMethod(arg: Int) {
            }

            2️⃣public func publicHelper(arg: Int) {
            }
        }
        """,
      expected: """
        import XCTest

        final class MyTests: XCTestCase {
            func testExample() {
                helperMethod(arg: 0)
            }

            private func helperMethod(arg: Int) {
            }

            private func publicHelper(arg: Int) {
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "make test helper 'private'"),
        FindingSpec("2️⃣", message: "make test helper 'private'"),
      ]
    )
  }

  @Test func xcTestPropertiesMadePrivate() {
    assertFormatting(
      RequireSuiteAccessControl.self,
      input: """
        import XCTest

        final class MyTests: XCTestCase {
            1️⃣var someProperty: String = ""
            2️⃣public var anotherProperty: Int = 0

            func testExample() {
                XCTAssertEqual(someProperty, "")
            }
        }
        """,
      expected: """
        import XCTest

        final class MyTests: XCTestCase {
            private var someProperty: String = ""
            private var anotherProperty: Int = 0

            func testExample() {
                XCTAssertEqual(someProperty, "")
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "make test helper 'private'"),
        FindingSpec("2️⃣", message: "make test helper 'private'"),
      ]
    )
  }

  @Test func xcTestClassMadeInternal() {
    assertFormatting(
      RequireSuiteAccessControl.self,
      input: """
        import XCTest

        1️⃣public final class MyTests: XCTestCase {
            func testExample() {
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
        FindingSpec("1️⃣", message: "remove 'public' from test suite type"),
      ]
    )
  }

  @Test func xcTestPreservesStaticMembers() {
    assertFormatting(
      RequireSuiteAccessControl.self,
      input: """
        import XCTest

        final class MyTests: XCTestCase {
            static var sharedState: String = ""

            func testExample() {
                XCTAssertEqual(Self.sharedState, "")
            }

            static func helperMethod() {
            }
        }
        """,
      expected: """
        import XCTest

        final class MyTests: XCTestCase {
            static var sharedState: String = ""

            func testExample() {
                XCTAssertEqual(Self.sharedState, "")
            }

            static func helperMethod() {
            }
        }
        """,
      findings: []
    )
  }

  @Test func xcTestPreservesOverrideAndObjc() {
    assertFormatting(
      RequireSuiteAccessControl.self,
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

  @Test func xcTestInitMadeInternal() {
    assertFormatting(
      RequireSuiteAccessControl.self,
      input: """
        import XCTest

        final class MyTests: XCTestCase {
            private let dependency: Dependency = Dependency()

            1️⃣public init() {
            }

            func testExample() {
                XCTAssertTrue(true)
            }
        }
        """,
      expected: """
        import XCTest

        final class MyTests: XCTestCase {
            private let dependency: Dependency = Dependency()

            init() {
            }

            func testExample() {
                XCTAssertTrue(true)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove explicit access control from test method"),
      ]
    )
  }

  // MARK: - Swift Testing

  @Test func swiftTestingHelpersMadePrivate() {
    assertFormatting(
      RequireSuiteAccessControl.self,
      input: """
        import Testing

        struct MyFeatureTests {
            @Test func featureWorks() {
                helperMethod()
            }

            1️⃣func helperMethod() {
            }

            2️⃣public func publicHelper() {
            }
        }
        """,
      expected: """
        import Testing

        struct MyFeatureTests {
            @Test func featureWorks() {
                helperMethod()
            }

            private func helperMethod() {
            }

            private func publicHelper() {
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "make test helper 'private'"),
        FindingSpec("2️⃣", message: "make test helper 'private'"),
      ]
    )
  }

  @Test func swiftTestingPrivateTestFunctionsMadeInternal() {
    assertFormatting(
      RequireSuiteAccessControl.self,
      input: """
        import Testing

        struct MyFeatureTests {
            @Test 1️⃣private func featureWorks() {
                #expect(true)
            }

            @Test 2️⃣fileprivate func anotherFeature() {
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

            @Test func anotherFeature() {
                #expect(true)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove explicit access control from test method"),
        FindingSpec("2️⃣", message: "remove explicit access control from test method"),
      ]
    )
  }

  @Test func swiftTestingTypeMadeInternal() {
    assertFormatting(
      RequireSuiteAccessControl.self,
      input: """
        import Testing

        1️⃣public struct MyFeatureTests {
            @Test func featureWorks() {
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
        FindingSpec("1️⃣", message: "remove 'public' from test suite type"),
      ]
    )
  }

  @Test func swiftTestingPropertiesMadePrivate() {
    assertFormatting(
      RequireSuiteAccessControl.self,
      input: """
        import Testing

        struct MyFeatureTests {
            1️⃣var someProperty: String = ""
            2️⃣public var anotherProperty: Int = 0

            @Test func featureWorks() {
                #expect(someProperty == "")
            }
        }
        """,
      expected: """
        import Testing

        struct MyFeatureTests {
            private var someProperty: String = ""
            private var anotherProperty: Int = 0

            @Test func featureWorks() {
                #expect(someProperty == "")
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "make test helper 'private'"),
        FindingSpec("2️⃣", message: "make test helper 'private'"),
      ]
    )
  }

  // MARK: - Base Classes & Edge Cases

  @Test func doesNotApplyToBaseClasses() {
    assertFormatting(
      RequireSuiteAccessControl.self,
      input: """
        import XCTest

        public class MyFeatureTestsBase: XCTestCase {
            public func helperMethod() {
            }

            public var someProperty: String = ""
        }
        """,
      expected: """
        import XCTest

        public class MyFeatureTestsBase: XCTestCase {
            public func helperMethod() {
            }

            public var someProperty: String = ""
        }
        """,
      findings: []
    )
  }

  @Test func doesNotApplyWhenBothFrameworksImported() {
    assertFormatting(
      RequireSuiteAccessControl.self,
      input: """
        import XCTest
        import Testing

        final class MyTests: XCTestCase {
            func testExample() {
                XCTAssertTrue(true)
            }

            func helperMethod() {
            }

            var someProperty: String = ""
        }
        """,
      expected: """
        import XCTest
        import Testing

        final class MyTests: XCTestCase {
            func testExample() {
                XCTAssertTrue(true)
            }

            func helperMethod() {
            }

            var someProperty: String = ""
        }
        """,
      findings: []
    )
  }

  @Test func preservesDisabledTestMethods() {
    assertFormatting(
      RequireSuiteAccessControl.self,
      input: """
        import XCTest

        final class MyTests: XCTestCase {
            func disable_testExample() {
                XCTAssertTrue(true)
            }

            func skip_testFeature() {
                XCTAssertTrue(false)
            }
        }
        """,
      expected: """
        import XCTest

        final class MyTests: XCTestCase {
            func disable_testExample() {
                XCTAssertTrue(true)
            }

            func skip_testFeature() {
                XCTAssertTrue(false)
            }
        }
        """,
      findings: []
    )
  }

  @Test func ignoresTypesWithParameterizedInit() {
    assertFormatting(
      RequireSuiteAccessControl.self,
      input: """
        import XCTest

        final class MyHelperClass: XCTestCase {
            let dependency: String

            init(dependency: String) {
                self.dependency = dependency
            }

            func example() {
                XCTAssertTrue(true)
            }
        }
        """,
      expected: """
        import XCTest

        final class MyHelperClass: XCTestCase {
            let dependency: String

            init(dependency: String) {
                self.dependency = dependency
            }

            func example() {
                XCTAssertTrue(true)
            }
        }
        """,
      findings: []
    )
  }
}
