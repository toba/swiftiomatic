struct PreferTypeCheckingConfiguration: RuleConfiguration {
    let id = "prefer_type_checking"
    let name = "Prefer Type Checking"
    let summary = "Prefer `a is X` to `a as? X != nil`"
    let isCorrectable = true
}
