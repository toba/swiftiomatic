struct MultilineParametersBracketsConfiguration: RuleConfiguration {
    let id = "multiline_parameters_brackets"
    let name = "Multiline Parameters Brackets"
    let summary = "Multiline parameters should have their surrounding brackets in a new line"
    let isOptIn = true
    let requiresSourceKit = true
}
