struct PeriodSpacingConfiguration: RuleConfiguration {
    let id = "period_spacing"
    let name = "Period Spacing"
    let summary = "Periods should not be followed by more than one space"
    let isCorrectable = true
    let isOptIn = true
}
