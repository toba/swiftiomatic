struct VerticalParameterAlignmentConfiguration: RuleConfiguration {
    let id = "vertical_parameter_alignment"
    let name = "Vertical Parameter Alignment"
    let summary = "Function parameters should be aligned vertically if they're in multiple lines in a declaration"
    var nonTriggeringExamples: [Example] {
        VerticalParameterAlignmentRuleExamples.nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        VerticalParameterAlignmentRuleExamples.triggeringExamples
    }
}
