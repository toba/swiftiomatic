struct ReduceIntoConfiguration: RuleConfiguration {
    let id = "reduce_into"
    let name = "Reduce into"
    let summary = "Prefer `reduce(into:_:)` over `reduce(_:_:)` for copy-on-write types"
    let isOptIn = true
}
