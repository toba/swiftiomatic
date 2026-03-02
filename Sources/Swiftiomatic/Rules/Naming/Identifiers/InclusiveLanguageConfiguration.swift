struct InclusiveLanguageConfiguration: RuleConfiguration {
    let id = "inclusive_language"
    let name = "Inclusive Language"
    let summary = ""
    var nonTriggeringExamples: [Example] {
        InclusiveLanguageRuleExamples.nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        InclusiveLanguageRuleExamples.triggeringExamples
    }
}
