struct FlatMapOverMapReduceConfiguration: RuleConfiguration {
    let id = "flatmap_over_map_reduce"
    let name = "Flat Map over Map Reduce"
    let summary = "Prefer `flatMap` over `map` followed by `reduce([], +)`"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("let foo = bar.map { $0.count }.reduce(0, +)"),
              Example("let foo = bar.flatMap { $0.array }"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("let foo = ↓bar.map { $0.array }.reduce([], +)")
            ]
    }
}
