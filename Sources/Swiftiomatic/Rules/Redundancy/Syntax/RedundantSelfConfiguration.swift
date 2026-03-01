struct RedundantSelfConfiguration: RuleConfiguration {
    let id = "redundant_self"
    let name = "Redundant Self"
    let summary = "Explicit use of 'self' is not required"
    let isCorrectable = true
    let isOptIn = true
    let deprecatedAliases: Set<String> = ["redundant_self_in_closure"]
}
