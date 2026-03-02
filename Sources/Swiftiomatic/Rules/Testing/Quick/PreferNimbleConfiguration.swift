struct PreferNimbleConfiguration: RuleConfiguration {
    let id = "prefer_nimble"
    let name = "Prefer Nimble"
    let summary = "Prefer Nimble matchers over XCTAssert functions"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("expect(foo) == 1"),
              Example("expect(foo).to(equal(1))"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("↓XCTAssertTrue(foo)"),
              Example("↓XCTAssertEqual(foo, 2)"),
              Example("↓XCTAssertNotEqual(foo, 2)"),
              Example("↓XCTAssertNil(foo)"),
              Example("↓XCTAssert(foo)"),
              Example("↓XCTAssertGreaterThan(foo, 10)"),
            ]
    }
}
