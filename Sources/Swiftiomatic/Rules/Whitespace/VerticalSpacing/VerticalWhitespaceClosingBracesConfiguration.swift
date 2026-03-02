struct VerticalWhitespaceClosingBracesConfiguration: RuleConfiguration {
    let id = "vertical_whitespace_closing_braces"
    let name = "Vertical Whitespace before Closing Braces"
    let summary = "Don't include vertical whitespace (empty line) before closing braces"
    let isCorrectable = true
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        VerticalWhitespaceClosingBracesRuleExamples.violatingToValidExamples
              .values.sorted() + VerticalWhitespaceClosingBracesRuleExamples.nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        Array(
              VerticalWhitespaceClosingBracesRuleExamples.violatingToValidExamples.keys.sorted(),
            )
    }
    var corrections: [Example: Example] {
        VerticalWhitespaceClosingBracesRuleExamples.violatingToValidExamples
              .removingViolationMarkers()
    }
}
