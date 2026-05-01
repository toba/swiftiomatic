@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct EnforceSwiftTestingNamesTests: RuleTesting {

  @Test func removesTestPrefixFromMethod() {
    assertFormatting(
      EnforceSwiftTestingNames.self,
      input: """
        import Testing

        struct MyFeatureTests {
            @Test func 1️⃣testMyFeatureHasNoBugs() {
                let myFeature = MyFeature()
                myFeature.runAction()
                #expect(!myFeature.hasBugs)
            }

            @Test("Features work as expected", arguments: [
                .foo,
                .bar,
                .baaz,
            ])
            func 2️⃣testFeatureWorksAsExpected(_ feature: Feature) {
                let myFeature = MyFeature()
                myFeature.run(feature)
                #expect(myFeature.worksAsExpected)
            }
        }
        """,
      expected: """
        import Testing

        struct MyFeatureTests {
            @Test func myFeatureHasNoBugs() {
                let myFeature = MyFeature()
                myFeature.runAction()
                #expect(!myFeature.hasBugs)
            }

            @Test("Features work as expected", arguments: [
                .foo,
                .bar,
                .baaz,
            ])
            func featureWorksAsExpected(_ feature: Feature) {
                let myFeature = MyFeature()
                myFeature.run(feature)
                #expect(myFeature.worksAsExpected)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove 'test' prefix from '@Test' function 'testMyFeatureHasNoBugs'"),
        FindingSpec("2️⃣", message: "remove 'test' prefix from '@Test' function 'testFeatureWorksAsExpected'"),
      ]
    )
  }

  @Test func doesNotRenameToKeywordOrDigit() {
    assertFormatting(
      EnforceSwiftTestingNames.self,
      input: """
        import Testing

        struct MyFeatureTests {
            @Test func test123() {
                #expect((1 + 2) == 3)
            }

            @Test func testInit() {
                #expect(Foo() != nil)
            }

            @Test func testSubscript() {
                #expect(foo[bar] != nil)
            }

            @Test func testNil() {
                #expect(foo.optionalFoo == nil)
            }

            @Test func test() {
                #expect(test.succeeds)
            }
        }
        """,
      expected: """
        import Testing

        struct MyFeatureTests {
            @Test func test123() {
                #expect((1 + 2) == 3)
            }

            @Test func testInit() {
                #expect(Foo() != nil)
            }

            @Test func testSubscript() {
                #expect(foo[bar] != nil)
            }

            @Test func testNil() {
                #expect(foo.optionalFoo == nil)
            }

            @Test func test() {
                #expect(test.succeeds)
            }
        }
        """,
      findings: []
    )
  }

  @Test func doesNotRenameToExistingFunctionName() {
    assertFormatting(
      EnforceSwiftTestingNames.self,
      input: """
        import Testing

        struct MyFeatureTests {
            @Test func testOnePlusTwo() {
                #expect(onePlusTwo() == 3)
            }

            func onePlusTwo() -> Int {
                1 + 2
            }
        }
        """,
      expected: """
        import Testing

        struct MyFeatureTests {
            @Test func testOnePlusTwo() {
                #expect(onePlusTwo() == 3)
            }

            func onePlusTwo() -> Int {
                1 + 2
            }
        }
        """,
      findings: []
    )
  }

  @Test func preservesXCTestMethodNames() {
    assertFormatting(
      EnforceSwiftTestingNames.self,
      input: """
        import XCTest

        final class MyFeatureTests: XCTestCase {
            func testOnePlusTwo() {
                XCTAssertEqual(onePlusTwo(), 3)
            }
        }
        """,
      expected: """
        import XCTest

        final class MyFeatureTests: XCTestCase {
            func testOnePlusTwo() {
                XCTAssertEqual(onePlusTwo(), 3)
            }
        }
        """,
      findings: []
    )
  }

  @Test func removesTestPrefixFromBacktickedNames() {
    assertFormatting(
      EnforceSwiftTestingNames.self,
      input: """
        import Testing

        struct MyFeatureTests {
            @Test func 1️⃣`test my feature has no bugs`() {
                #expect(true)
            }

            @Test func 2️⃣`Test Feature Works As Expected`() {
                #expect(true)
            }
        }
        """,
      expected: """
        import Testing

        struct MyFeatureTests {
            @Test func `my feature has no bugs`() {
                #expect(true)
            }

            @Test func `Feature Works As Expected`() {
                #expect(true)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove 'test' prefix from '@Test' function 'test my feature has no bugs'"),
        FindingSpec("2️⃣", message: "remove 'test' prefix from '@Test' function 'Test Feature Works As Expected'"),
      ]
    )
  }

  @Test func preservesNamesWithoutTestPrefix() {
    assertFormatting(
      EnforceSwiftTestingNames.self,
      input: """
        import Testing

        struct MyFeatureTests {
            @Test func myFeatureWorks() {
                #expect(true)
            }

            @Test func `my feature has no bugs`() {
                #expect(true)
            }
        }
        """,
      expected: """
        import Testing

        struct MyFeatureTests {
            @Test func myFeatureWorks() {
                #expect(true)
            }

            @Test func `my feature has no bugs`() {
                #expect(true)
            }
        }
        """,
      findings: []
    )
  }
}
