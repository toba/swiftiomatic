struct EmptyParametersConfiguration: RuleConfiguration {
    let id = "empty_parameters"
    let name = "Empty Parameters"
    let summary = "Prefer `() -> ` over `Void -> `"
    let isCorrectable = true
}
