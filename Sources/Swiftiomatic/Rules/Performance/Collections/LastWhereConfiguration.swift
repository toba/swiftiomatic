struct LastWhereConfiguration: RuleConfiguration {
    let id = "last_where"
    let name = "Last Where"
    let summary = "Prefer using `.last(where:)` over `.filter { }.last` in collections"
    let isOptIn = true
}
