struct PreferZeroOverExplicitInitConfiguration: RuleConfiguration {
    let id = "prefer_zero_over_explicit_init"
    let name = "Prefer Zero Over Explicit Init"
    let summary = "Prefer `.zero` over explicit init with zero parameters (e.g. `CGPoint(x: 0, y: 0)`)"
    let isCorrectable = true
    let isOptIn = true
}
