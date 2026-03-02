struct LegacyRandomConfiguration: RuleConfiguration {
    let id = "legacy_random"
    let name = "Legacy Random"
    let summary = "Prefer using `type.random(in:)` over legacy functions"
    var nonTriggeringExamples: [Example] {
        [
              Example("Int.random(in: 0..<10)"),
              Example("Double.random(in: 8.6...111.34)"),
              Example("Float.random(in: 0 ..< 1)"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("↓arc4random()"),
              Example("↓arc4random_uniform(83)"),
              Example("↓drand48()"),
            ]
    }
}
