struct RedundantDiscardableLetConfiguration: RuleConfiguration {
    let id = "redundant_discardable_let"
    let name = "Redundant Discardable Let"
    let summary = "Prefer `_ = foo()` over `let _ = foo()` when discarding a result from a function"
    let isCorrectable = true
}
