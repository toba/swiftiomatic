struct BlankLinesBetweenChainedFunctionsConfiguration: RuleConfiguration {
    let id = "blank_lines_between_chained_functions"
    let name = "Blank Lines Between Chained Functions"
    let summary = "There should be no blank lines between chained function calls"
    let scope: Scope = .format
}
