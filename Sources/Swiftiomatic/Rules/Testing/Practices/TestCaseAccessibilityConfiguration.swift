struct TestCaseAccessibilityConfiguration: RuleConfiguration {
    let id = "test_case_accessibility"
    let name = "Test Case Accessibility"
    let summary = "Test cases should only contain private non-test members"
    let isCorrectable = true
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        TestCaseAccessibilityRuleExamples.nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        TestCaseAccessibilityRuleExamples.triggeringExamples
    }
    var corrections: [Example: Example] {
        TestCaseAccessibilityRuleExamples.corrections
    }
}
