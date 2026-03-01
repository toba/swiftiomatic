struct NumberFormattingConfiguration: RuleConfiguration {
    let id = "number_formatting"
    let name = "Number Formatting"
    let summary = "Large numeric literals should use underscores for grouping"
    let scope: Scope = .suggest
}
