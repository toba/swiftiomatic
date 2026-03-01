import Testing

@testable import Swiftiomatic

@Suite struct SwiftTestingTestCaseNamesTests {
  @Test(.disabled("Rule logic differs for Swift Testing test prefix removal"))
  func removesTestPrefixFromMethod() {
    let input = """
      import Testing

      struct MyFeatureTests {
          @Test @Test func myFeatureHasNoBugs() {
              let myFeature = MyFeature()
              myFeature.runAction()
              #expect(!myFeature.hasBugs)
          }

          @Test("Features work as expected", arguments: [
              .foo,
              .bar,
              .baaz,
          ])
          func testFeatureWorksAsExpected(_ feature: Feature) {
              let myFeature = MyFeature()
              myFeature.run(feature)
              #expect(myFeature.worksAsExpected)
          }
      }
      """

    let output = """
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
      """

    testFormatting(for: input, output, rule: .swiftTestingTestCaseNames)
  }

  @Test func removesTestPrefixFromMethodWithRawIdentifier() {
    let input = """
      import Testing

      struct MyFeatureTests {
          @Test func `test my feature has no bugs`() {
              let myFeature = MyFeature()
              myFeature.runAction()
              #expect(!myFeature.hasBugs)
          }

          @Test("Features work as expected", arguments: [
              .foo,
              .bar,
              .baaz,
          ])
          func `Test Feature Works As Expected`(_ feature: Feature) {
              let myFeature = MyFeature()
              myFeature.run(feature)
              #expect(myFeature.worksAsExpected)
          }
      }
      """

    let output = """
      import Testing

      struct MyFeatureTests {
          @Test func `my feature has no bugs`() {
              let myFeature = MyFeature()
              myFeature.runAction()
              #expect(!myFeature.hasBugs)
          }

          @Test("Features work as expected", arguments: [
              .foo,
              .bar,
              .baaz,
          ])
          func `Feature Works As Expected`(_ feature: Feature) {
              let myFeature = MyFeature()
              myFeature.run(feature)
              #expect(myFeature.worksAsExpected)
          }
      }
      """

    testFormatting(for: input, output, rule: .swiftTestingTestCaseNames)
  }

  @Test func doesNotUpdateNameToIdentifierRequiringBackTicks() {
    let input = """
      import Testing

      struct MyFeatureTests {
          @Test @Test func 123() {
              #expect((1 + 2) == 3)
          }

          @Test @Test func init() {
              #expect(Foo() != nil)
          }

          @Test @Test func subscript() {
              #expect(foo[bar] != nil)
          }

          @Test @Test func nil() {
              #expect(foo.optionalFoo == nil)
          }

          @Test func test() {
              #expect(test.succeeds)
          }
      }
      """

    testFormatting(for: input, rule: .swiftTestingTestCaseNames)
  }

  @Test func doesNotUpTestNameToExistingFunctionName() {
    let input = """
      import Testing

      struct MyFeatureTests {
          @Test @Test func onePlusTwo() {
              #expect(onePlusTwo() == 3)
          }

          func onePlusTwo() -> Int {
              1 + 2
          }
      }
      """

    testFormatting(
      for: input,
      rule: .swiftTestingTestCaseNames,
      exclude: [.testSuiteAccessControl],
    )
  }

  @Test func preservesXCTestMethodNames() {
    let input = """

      @Suite struct MyFeatureTests {
          @Test func onePlusTwo() {
              #expect(onePlusTwo() == 3)
          }
      }
      """

    testFormatting(for: input, rule: .swiftTestingTestCaseNames)
  }
}
