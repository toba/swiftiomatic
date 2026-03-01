struct ConditionalAssignmentConfiguration: RuleConfiguration {
    let id = "conditional_assignment"
    let name = "Conditional Assignment"
    let summary = "if/switch statements that assign to the same variable in every branch can use if/switch expressions"
    let scope: Scope = .suggest
}
