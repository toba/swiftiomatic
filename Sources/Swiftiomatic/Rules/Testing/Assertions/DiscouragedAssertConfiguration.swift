struct DiscouragedAssertConfiguration: RuleConfiguration {
    let id = "discouraged_assert"
    let name = "Discouraged Assert"
    let summary = "Prefer `assertionFailure()` and/or `preconditionFailure()` over `assert(false)`"
    let isOptIn = true
}
