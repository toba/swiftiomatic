struct FirstWhereConfiguration: RuleConfiguration {
    let id = "first_where"
    let name = "First Where"
    let summary = "Prefer using `.first(where:)` over `.filter { }.first` in collections"
    let isOptIn = true
}
