struct RedundantClosureConfiguration: RuleConfiguration {
    let id = "redundant_closure"
    let name = "Redundant Closure"
    let summary = "Immediately-invoked closures with a single expression can be simplified"
    let scope: Scope = .format
}
