struct NestingConfiguration: RuleConfiguration {
    let id = "nesting"
    let name = "Nesting"
    let summary = "Types should be nested at most 1 level deep, and functions should be nested at most 2 levels deep."
    var nonTriggeringExamples: [Example] {
        NestingRuleExamples.nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        NestingRuleExamples.triggeringExamples
    }
}
