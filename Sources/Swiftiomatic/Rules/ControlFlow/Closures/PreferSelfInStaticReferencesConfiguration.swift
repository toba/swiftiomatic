struct PreferSelfInStaticReferencesConfiguration: RuleConfiguration {
    let id = "prefer_self_in_static_references"
    let name = "Prefer Self in Static References"
    let summary = "Use `Self` to refer to the surrounding type name"
    let isCorrectable = true
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        PreferSelfInStaticReferencesRuleExamples.nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        PreferSelfInStaticReferencesRuleExamples.triggeringExamples
    }
    var corrections: [Example: Example] {
        PreferSelfInStaticReferencesRuleExamples.corrections
    }
}
