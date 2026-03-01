struct RedundantPropertyConfiguration: RuleConfiguration {
    let id = "redundant_property"
    let name = "Redundant Property"
    let summary = "A local property assigned and immediately returned can be simplified to a direct return"
    let scope: Scope = .format
    let isCorrectable = true
}
