struct NumberSeparatorConfiguration: RuleConfiguration {
    let id = "number_separator"
    let name = "Number Separator"
    let summary = ""
    let isCorrectable = true
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        NumberSeparatorRuleExamples.nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        NumberSeparatorRuleExamples.triggeringExamples
    }
    var corrections: [Example: Example] {
        NumberSeparatorRuleExamples.corrections
    }
}
