struct RedundantBackticksConfiguration: RuleConfiguration {
    let id = "redundant_backticks"
    let name = "Redundant Backticks"
    let summary = "Backtick-escaped identifiers that are not keywords in their context are redundant"
    let scope: Scope = .format
    let isCorrectable = true
}
