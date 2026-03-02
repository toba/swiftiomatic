struct QuickDiscouragedCallConfiguration: RuleConfiguration {
    let id = "quick_discouraged_call"
    let name = "Quick Discouraged Call"
    let summary = "Discouraged call inside 'describe' and/or 'context' block."
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        QuickDiscouragedCallRuleExamples.nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        QuickDiscouragedCallRuleExamples.triggeringExamples
    }
}
