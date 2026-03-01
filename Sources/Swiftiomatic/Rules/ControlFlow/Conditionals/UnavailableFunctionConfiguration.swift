struct UnavailableFunctionConfiguration: RuleConfiguration {
    let id = "unavailable_function"
    let name = "Unavailable Function"
    let summary = "Unimplemented functions should be marked as unavailable"
    let isOptIn = true
}
