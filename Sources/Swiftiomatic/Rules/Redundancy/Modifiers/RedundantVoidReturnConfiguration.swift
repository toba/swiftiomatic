struct RedundantVoidReturnConfiguration: RuleConfiguration {
    let id = "redundant_void_return"
    let name = "Redundant Void Return"
    let summary = "Returning Void in a function declaration is redundant"
    let isCorrectable = true
}
