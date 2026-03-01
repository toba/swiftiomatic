struct GenericConsolidationConfiguration: RuleConfiguration {
    let id = "generic_consolidation"
    let name = "Generic Consolidation"
    let summary = "Suggests replacing 'any Protocol' with 'some Protocol' and detecting over-constrained generic parameters"
    let scope: Scope = .suggest
    let isOptIn = true
}
