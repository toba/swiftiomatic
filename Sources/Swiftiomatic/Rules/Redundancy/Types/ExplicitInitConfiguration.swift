struct ExplicitInitConfiguration: RuleConfiguration {
    let id = "explicit_init"
    let name = "Explicit Init"
    let summary = "Explicitly calling .init() should be avoided"
    let isCorrectable = true
    let isOptIn = true
}
