struct DiscouragedAssertConfiguration: RuleConfiguration {
    let id = "discouraged_assert"
    let name = "Discouraged Assert"
    let summary = "Prefer `assertionFailure()` and/or `preconditionFailure()` over `assert(false)`"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example(#"assert(true)"#),
              Example(#"assert(true, "foobar")"#),
              Example(#"assert(true, "foobar", file: "toto", line: 42)"#),
              Example(#"assert(false || true)"#),
              Example(#"XCTAssert(false)"#),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(#"↓assert(false)"#),
              Example(#"↓assert(false, "foobar")"#),
              Example(#"↓assert(false, "foobar", file: "toto", line: 42)"#),
              Example(#"↓assert(   false    , "foobar")"#),
            ]
    }
}
