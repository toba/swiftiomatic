struct ContainsOverRangeNilComparisonConfiguration: RuleConfiguration {
    let id = "contains_over_range_nil_comparison"
    let name = "Contains over Range Comparison to Nil"
    let summary = "Prefer `contains` over `range(of:) != nil` and `range(of:) == nil`"
    let isOptIn = true
}
