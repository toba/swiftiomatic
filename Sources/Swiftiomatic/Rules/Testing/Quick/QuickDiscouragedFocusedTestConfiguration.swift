struct QuickDiscouragedFocusedTestConfiguration: RuleConfiguration {
    let id = "quick_discouraged_focused_test"
    let name = "Quick Discouraged Focused Test"
    let summary = "Non-focused tests won't run as long as this test is focused"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        QuickDiscouragedFocusedTestRuleExamples.nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        QuickDiscouragedFocusedTestRuleExamples.triggeringExamples
    }
}
