struct EmptyBracesConfiguration: RuleConfiguration {
    let id = "empty_braces"
    let name = "Empty Braces"
    let summary = "Empty braces should not contain whitespace"
    let scope: Scope = .format
    let isCorrectable = true
}
