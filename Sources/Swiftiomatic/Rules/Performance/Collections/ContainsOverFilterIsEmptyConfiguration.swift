struct ContainsOverFilterIsEmptyConfiguration: RuleConfiguration {
    let id = "contains_over_filter_is_empty"
    let name = "Contains over Filter is Empty"
    let summary = "Prefer `contains` over using `filter(where:).isEmpty`"
    let isOptIn = true
}
