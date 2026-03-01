struct VerticalWhitespaceClosingBracesConfiguration: RuleConfiguration {
    let id = "vertical_whitespace_closing_braces"
    let name = "Vertical Whitespace before Closing Braces"
    let summary = "Don't include vertical whitespace (empty line) before closing braces"
    let isCorrectable = true
    let isOptIn = true
}
