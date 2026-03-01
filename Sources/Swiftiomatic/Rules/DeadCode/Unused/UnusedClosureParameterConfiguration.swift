struct UnusedClosureParameterConfiguration: RuleConfiguration {
    let id = "unused_closure_parameter"
    let name = "Unused Closure Parameter"
    let summary = "Unused parameter in a closure should be replaced with _"
    let isCorrectable = true
}
