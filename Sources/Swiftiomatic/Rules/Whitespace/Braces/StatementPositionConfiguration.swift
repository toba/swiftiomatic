struct StatementPositionConfiguration: RuleConfiguration {
    let id = "statement_position"
    let name = "Statement Position"
    let summary = "Else and catch should be on the same line, one space after the previous declaration"
    let isCorrectable = true
}
