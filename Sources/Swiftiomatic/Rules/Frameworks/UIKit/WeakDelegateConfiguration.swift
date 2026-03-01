struct WeakDelegateConfiguration: RuleConfiguration {
    let id = "weak_delegate"
    let name = "Weak Delegate"
    let summary = "Delegates should be weak to avoid reference cycles"
    let isOptIn = true
}
