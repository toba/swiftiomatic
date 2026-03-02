struct MultilineArgumentsConfiguration: RuleConfiguration {
    let id = "multiline_arguments"
    let name = "Multiline Arguments"
    let summary = "Arguments should be either on the same line, or one per line"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        MultilineArgumentsRuleExamples.nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        MultilineArgumentsRuleExamples.triggeringExamples
    }
}
