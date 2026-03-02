struct IdentifierNameConfiguration: RuleConfiguration {
    let id = "identifier_name"
    let name = "Identifier Name"
    let summary = "Identifier names should only contain alphanumeric characters and start with a lowercase character or should only contain capital letters. In an exception to the above, variable names may start with a capital letter when they are declared as static. Variable names should not be too long or too short."
    let deprecatedAliases: Set<String> = ["variable_name"]
    var nonTriggeringExamples: [Example] {
        IdentifierNameRuleExamples.nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        IdentifierNameRuleExamples.triggeringExamples
    }
}
