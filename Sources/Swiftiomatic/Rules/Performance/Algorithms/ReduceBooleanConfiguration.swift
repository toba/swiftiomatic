struct ReduceBooleanConfiguration: RuleConfiguration {
    let id = "reduce_boolean"
    let name = "Reduce Boolean"
    let summary = "Prefer using `.allSatisfy()` or `.contains()` over `reduce(true)` or `reduce(false)`."
}
