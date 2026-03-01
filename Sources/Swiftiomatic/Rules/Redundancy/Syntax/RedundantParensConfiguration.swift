struct RedundantParensConfiguration: RuleConfiguration {
    let id = "redundant_parens"
    let name = "Redundant Parentheses"
    let summary = "Redundant parentheses around expressions in control flow statements should be removed"
    let scope: Scope = .format
    let isCorrectable = true
}
