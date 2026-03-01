struct ProhibitedSuperConfiguration: RuleConfiguration {
    let id = "prohibited_super_call"
    let name = "Prohibited Calls to Super"
    let summary = "Some methods should not call super."
    let isOptIn = true
}
