struct ImplicitReturnConfiguration: RuleConfiguration {
    let id = "implicit_return"
    let name = "Implicit Return"
    let summary = "Prefer implicit returns in closures, functions and getters"
    let isCorrectable = true
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        ImplicitReturnRuleExamples.nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        ImplicitReturnRuleExamples.triggeringExamples
    }
    var corrections: [Example: Example] {
        ImplicitReturnRuleExamples.corrections
    }
}
