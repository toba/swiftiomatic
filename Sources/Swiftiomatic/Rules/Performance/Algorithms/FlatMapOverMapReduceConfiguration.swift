struct FlatMapOverMapReduceConfiguration: RuleConfiguration {
    let id = "flatmap_over_map_reduce"
    let name = "Flat Map over Map Reduce"
    let summary = "Prefer `flatMap` over `map` followed by `reduce([], +)`"
    let isOptIn = true
}
