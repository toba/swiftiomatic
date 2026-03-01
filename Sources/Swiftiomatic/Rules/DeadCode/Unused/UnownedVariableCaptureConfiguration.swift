struct UnownedVariableCaptureConfiguration: RuleConfiguration {
    let id = "unowned_variable_capture"
    let name = "Unowned Variable Capture"
    let summary = "Prefer capturing references as weak to avoid potential crashes"
    let isOptIn = true
}
