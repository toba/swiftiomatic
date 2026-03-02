struct TypeNameConfiguration: RuleConfiguration {
    let id = "type_name"
    let name = "Type Name"
    let summary = ""
    var nonTriggeringExamples: [Example] {
        TypeNameRuleExamples.nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        TypeNameRuleExamples.triggeringExamples
    }
}
