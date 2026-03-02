struct OpeningBraceConfiguration: RuleConfiguration {
    let id = "opening_brace"
    let name = "Opening Brace Spacing"
    let summary = ""
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        OpeningBraceRuleExamples.nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        OpeningBraceRuleExamples.triggeringExamples
    }
    var corrections: [Example: Example] {
        OpeningBraceRuleExamples.corrections
    }
}
