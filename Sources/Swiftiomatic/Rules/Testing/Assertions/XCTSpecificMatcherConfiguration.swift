struct XCTSpecificMatcherConfiguration: RuleConfiguration {
    let id = "xct_specific_matcher"
    let name = "XCTest Specific Matcher"
    let summary = "Prefer specific XCTest matchers."
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        XCTSpecificMatcherRuleExamples.nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        XCTSpecificMatcherRuleExamples.triggeringExamples
    }
    let rationale: String? = """
      Using specific matchers like `XCTAssertEqual`, `XCTAssertNotEqual`, `XCTAssertTrue`, `XCTAssertFalse`,
      `XCTAssertIdentical` and `XCTAssertNotIdentical` improves code readability and clarity. They more clearly
      state the intention of the assertion.

      Consider for example `XCTAssertTrue(foo == bar)`, which requires two details to grasp: that `foo` and `bar`
      are equal, and that the result of the comparison shall be true. Using `XCTAssertEqual(foo, bar)` makes it
      clear that the intention is to check equality, without needing to understand the underlying logic of the
      comparison.
      """
}
