struct VerticalWhitespaceBetweenCasesConfiguration: RuleConfiguration {
    let id = "vertical_whitespace_between_cases"
    let name = "Vertical Whitespace Between Cases"
    let summary = "Include a single empty line between switch cases"
    let isCorrectable = true
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        VerticalWhitespaceBetweenCasesRuleExamples.violatingToValidExamples
              .values.sorted() + VerticalWhitespaceBetweenCasesRuleExamples.nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        Array(
              VerticalWhitespaceBetweenCasesRuleExamples.violatingToValidExamples.keys.sorted(),
            )
    }
    var corrections: [Example: Example] {
        VerticalWhitespaceBetweenCasesRuleExamples.violatingToValidExamples
              .removingViolationMarkers()
    }
}
