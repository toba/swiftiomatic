struct DirectReturnConfiguration: RuleConfiguration {
    let id = "direct_return"
    let name = "Direct Return"
    let summary = "Directly return the expression instead of assigning it to a variable first"
    let isCorrectable = true
    let isOptIn = true
}
