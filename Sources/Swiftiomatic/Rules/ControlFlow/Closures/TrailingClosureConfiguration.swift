struct TrailingClosureConfiguration: RuleConfiguration {
    let id = "trailing_closure"
    let name = "Trailing Closure"
    let summary = "Trailing closure syntax should be used whenever possible"
    let isCorrectable = true
    let isOptIn = true
}
