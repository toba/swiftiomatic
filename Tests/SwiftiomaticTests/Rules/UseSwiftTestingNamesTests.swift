@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseSwiftTestingNamesTests: RuleTesting {

  @Test func removesTestPrefixFromMethod() {
    assertFormatting(
      UseSwiftTestingNames.self,
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
      UseSwiftTestingNames.self,
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
      UseSwiftTestingNames.self,
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
      UseSwiftTestingNames.self,
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
      UseSwiftTestingNames.self,
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

  // MARK: - Raw identifier mode

  /// Builds a configuration that enables `UseSwiftTestingNames` in `.rawIdentifier` style.
  private func rawIdentifierConfig() -> Configuration {
    var config = Configuration.forTesting
    config.disableAllRules()
    var ruleConfig = SwiftTestingNamesConfiguration()
    ruleConfig.rewrite = true
    ruleConfig.lint = .warn
    ruleConfig.style = .rawIdentifier
    config[UseSwiftTestingNames.self] = ruleConfig
    return config
  }

  @Test func convertsCamelCaseToRawIdentifier() {
    assertFormatting(
      UseSwiftTestingNames.self,
      input: """
        import Testing

        struct MyFeatureTests {
            @Test func 1️⃣testMyFeatureHasNoBugs() {
                #expect(true)
            }

            @Test func 2️⃣featureWorksAsExpected() {
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

            @Test func `feature works as expected`() {
                #expect(true)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "rename '@Test' function 'testMyFeatureHasNoBugs' to raw identifier '`my feature has no bugs`'"),
        FindingSpec("2️⃣", message: "rename '@Test' function 'featureWorksAsExpected' to raw identifier '`feature works as expected`'"),
      ],
      configuration: rawIdentifierConfig()
    )
  }

  @Test func rawIdentifierLeavesBacktickedAndPurelyNumericNamesAlone() {
    assertFormatting(
      UseSwiftTestingNames.self,
      input: """
        import Testing

        struct MyFeatureTests {
            @Test func `already a raw identifier`() {
                #expect(true)
            }

            @Test func test123() {
                #expect(true)
            }
        }
        """,
      expected: """
        import Testing

        struct MyFeatureTests {
            @Test func `already a raw identifier`() {
                #expect(true)
            }

            @Test func test123() {
                #expect(true)
            }
        }
        """,
      findings: [],
      configuration: rawIdentifierConfig()
    )
  }

  @Test func rawIdentifierLeavesSingleWordNamesAlone() {
    assertFormatting(
      UseSwiftTestingNames.self,
      input: """
        import Testing

        struct MyFeatureTests {
            @Test func insert() {
                #expect(true)
            }

            @Test func lookup() {
                #expect(true)
            }
        }
        """,
      expected: """
        import Testing

        struct MyFeatureTests {
            @Test func insert() {
                #expect(true)
            }

            @Test func lookup() {
                #expect(true)
            }
        }
        """,
      findings: [],
      configuration: rawIdentifierConfig()
    )
  }

  @Test func rawIdentifierLeavesNamesAloneWhenTestCarriesADisplayName() {
    assertFormatting(
      UseSwiftTestingNames.self,
      input: """
        import Testing

        struct MyFeatureTests {
            @Test("my feature has no bugs")
            func testMyFeatureHasNoBugs() {
                #expect(true)
            }

            @Test("features work", arguments: [Feature.foo])
            func testFeatureWorks(_ feature: Feature) {
                #expect(true)
            }

            @Test(arguments: [Feature.foo])
            func 1️⃣testFeatureWorksUnnamed(_ feature: Feature) {
                #expect(true)
            }
        }
        """,
      expected: """
        import Testing

        struct MyFeatureTests {
            @Test("my feature has no bugs")
            func testMyFeatureHasNoBugs() {
                #expect(true)
            }

            @Test("features work", arguments: [Feature.foo])
            func testFeatureWorks(_ feature: Feature) {
                #expect(true)
            }

            @Test(arguments: [Feature.foo])
            func `feature works unnamed`(_ feature: Feature) {
                #expect(true)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "rename '@Test' function 'testFeatureWorksUnnamed' to raw identifier '`feature works unnamed`'"),
      ],
      configuration: rawIdentifierConfig()
    )
  }

  @Test func preservesNamesWithoutTestPrefix() {
    assertFormatting(
      UseSwiftTestingNames.self,
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
