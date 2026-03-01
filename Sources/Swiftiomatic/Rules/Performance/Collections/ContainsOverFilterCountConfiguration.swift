struct ContainsOverFilterCountConfiguration: RuleConfiguration {
    let id = "contains_over_filter_count"
    let name = "Contains over Filter Count"
    let summary = "Prefer `contains` over comparing `filter(where:).count` to 0"
    let isOptIn = true
}
