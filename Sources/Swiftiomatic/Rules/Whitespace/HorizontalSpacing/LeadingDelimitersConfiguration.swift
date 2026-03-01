struct LeadingDelimitersConfiguration: RuleConfiguration {
    let id = "leading_delimiters"
    let name = "Leading Delimiters"
    let summary = "Delimiters should not appear at the start of a line; move them to the end of the previous line"
    let scope: Scope = .format
}
