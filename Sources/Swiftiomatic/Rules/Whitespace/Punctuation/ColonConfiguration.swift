struct ColonConfiguration: RuleConfiguration {
    let id = "colon"
    let name = "Colon Spacing"
    let summary = ""
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        ColonRuleExamples.nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        ColonRuleExamples.triggeringExamples
    }
    var corrections: [Example: Example] {
        ColonRuleExamples.corrections
    }
}
