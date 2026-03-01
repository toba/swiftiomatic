struct LiteralExpressionEndIndentationConfiguration: RuleConfiguration {
    let id = "literal_expression_end_indentation"
    let name = "Literal Expression End Indentation"
    let summary = "Array and dictionary literal end should have the same indentation as the line that started it"
    let isCorrectable = true
    let isOptIn = true
    let requiresSourceKit = true
}
