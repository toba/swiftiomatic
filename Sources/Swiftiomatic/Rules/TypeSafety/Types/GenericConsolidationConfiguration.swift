struct GenericConsolidationConfiguration: RuleConfiguration {
    let id = "generic_consolidation"
    let name = "Generic Consolidation"
    let summary = "Suggests replacing 'any Protocol' with 'some Protocol' and detecting over-constrained generic parameters"
    let scope: Scope = .suggest
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("func process(_ items: some Sequence) { }"),
              Example("var delegate: any Delegate"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("func process(_ items: ↓any Collection) { for item in items { } }")
            ]
    }
}
