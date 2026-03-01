struct XCTSpecificMatcherConfiguration: RuleConfiguration {
    let id = "xct_specific_matcher"
    let name = "XCTest Specific Matcher"
    let summary = "Prefer specific XCTest matchers."
    let isOptIn = true
}
