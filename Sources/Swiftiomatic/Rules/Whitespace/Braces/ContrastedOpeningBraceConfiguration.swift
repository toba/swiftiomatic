struct ContrastedOpeningBraceConfiguration: RuleConfiguration {
    let id = "contrasted_opening_brace"
    let name = "Contrasted Opening Brace"
    let summary = ""
    let isCorrectable = true
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        ContrastedOpeningBraceRuleExamples.nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        ContrastedOpeningBraceRuleExamples.triggeringExamples
    }
    var corrections: [Example: Example] {
        ContrastedOpeningBraceRuleExamples.corrections
    }
}
