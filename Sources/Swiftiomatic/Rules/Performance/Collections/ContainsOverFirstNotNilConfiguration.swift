struct ContainsOverFirstNotNilConfiguration: RuleConfiguration {
    let id = "contains_over_first_not_nil"
    let name = "Contains over First not Nil"
    let summary = "Prefer `contains` over `first(where:) != nil` and `firstIndex(where:) != nil`."
    let isOptIn = true
}
