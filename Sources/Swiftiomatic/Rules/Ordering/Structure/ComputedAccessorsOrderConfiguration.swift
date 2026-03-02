struct ComputedAccessorsOrderConfiguration: RuleConfiguration {
    let id = "computed_accessors_order"
    let name = "Computed Accessors Order"
    let summary = "Getter and setters in computed properties and subscripts should be in a consistent order."
    var nonTriggeringExamples: [Example] {
        ComputedAccessorsOrderRuleExamples.nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        ComputedAccessorsOrderRuleExamples.triggeringExamples
    }
}
