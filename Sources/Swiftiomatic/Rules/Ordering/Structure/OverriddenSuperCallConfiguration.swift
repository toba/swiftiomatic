struct OverriddenSuperCallConfiguration: RuleConfiguration {
    let id = "overridden_super_call"
    let name = "Overridden Method Calls Super"
    let summary = "Some overridden methods should always call super."
    let isOptIn = true
}
