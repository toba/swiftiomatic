struct ModifierOrderConfiguration: RuleConfiguration {
    let id = "modifier_order"
    let name = "Modifier Order"
    let summary = "Modifier order should be consistent."
    let isCorrectable = true
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        ModifierOrderRuleExamples.nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        ModifierOrderRuleExamples.triggeringExamples
    }
}
