struct ImplicitOptionalInitializationConfiguration: RuleConfiguration {
    let id = "implicit_optional_initialization"
    let name = "Implicit Optional Initialization"
    let summary = "Optionals should be consistently initialized, either with `= nil` or without."
    let isCorrectable = true
    let deprecatedAliases: Set<String> = ["redundant_optional_initialization"]
    var nonTriggeringExamples: [Example] {
        ImplicitOptionalInitializationRuleExamples.nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        ImplicitOptionalInitializationRuleExamples.triggeringExamples
    }
    var corrections: [Example: Example] {
        ImplicitOptionalInitializationRuleExamples.corrections
    }
}
