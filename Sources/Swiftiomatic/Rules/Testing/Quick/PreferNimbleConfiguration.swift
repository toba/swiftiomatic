struct PreferNimbleConfiguration: RuleConfiguration {
    let id = "prefer_nimble"
    let name = "Prefer Nimble"
    let summary = "Prefer Nimble matchers over XCTAssert functions"
    let isOptIn = true
}
