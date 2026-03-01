struct ClosureEndIndentationConfiguration: RuleConfiguration {
    let id = "closure_end_indentation"
    let name = "Closure End Indentation"
    let summary = "Closure end should have the same indentation as the line that started it."
    let isCorrectable = true
    let isOptIn = true
}
