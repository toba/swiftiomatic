struct ExpiringTodoConfiguration: RuleConfiguration {
    let id = "expiring_todo"
    let name = "Expiring Todo"
    let summary = "TODOs and FIXMEs should be resolved prior to their expiry date."
    let isOptIn = true
}
