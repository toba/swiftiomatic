struct RedundantGetConfiguration: RuleConfiguration {
    let id = "redundant_get"
    let name = "Redundant Get"
    let summary = "Computed read-only properties should avoid using the `get` keyword"
    let isCorrectable = true
}
