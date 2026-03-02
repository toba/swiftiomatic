struct UnusedClosureParameterConfiguration: RuleConfiguration {
    let id = "unused_closure_parameter"
    let name = "Unused Closure Parameter"
    let summary = "Unused parameter in a closure should be replaced with _"
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        UnusedClosureParameterRuleExamples.nonTriggering
    }
    var triggeringExamples: [Example] {
        UnusedClosureParameterRuleExamples.triggering
    }
    var corrections: [Example: Example] {
        UnusedClosureParameterRuleExamples.corrections
    }
}
