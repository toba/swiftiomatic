struct MultilineParametersConfiguration: RuleConfiguration {
    let id = "multiline_parameters"
    let name = "Multiline Parameters"
    let summary = "Functions and methods parameters should be either on the same line, or one per line"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        MultilineParametersRuleExamples.nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        MultilineParametersRuleExamples.triggeringExamples
    }
}
