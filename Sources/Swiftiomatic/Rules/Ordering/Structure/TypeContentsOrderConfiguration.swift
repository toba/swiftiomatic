struct TypeContentsOrderConfiguration: RuleConfiguration {
    let id = "type_contents_order"
    let name = "Type Contents Order"
    let summary = "Specifies the order of subtypes, properties, methods & more within a type."
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        TypeContentsOrderRuleExamples.nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        TypeContentsOrderRuleExamples.triggeringExamples
    }
}
