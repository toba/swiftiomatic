struct OperatorUsageWhitespaceConfiguration: RuleConfiguration {
    let id = "operator_usage_whitespace"
    let name = "Operator Usage Whitespace"
    let summary = "Operators should be surrounded by a single whitespace when they are being used"
    let isCorrectable = true
    let isOptIn = true
}
