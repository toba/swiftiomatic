struct PreferKeyPathConfiguration: RuleConfiguration {
    let id = "prefer_key_path"
    let name = "Prefer Key Path"
    let summary = "Use a key path argument instead of a closure with property access"
    let isCorrectable = true
    let isOptIn = true
}
