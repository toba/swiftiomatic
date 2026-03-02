struct RedundantObjcAttributeConfiguration: RuleConfiguration {
    let id = "redundant_objc_attribute"
    let name = "Redundant @objc Attribute"
    let summary = "Objective-C attribute (@objc) is redundant in declaration"
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        RedundantObjcAttributeRuleExamples.nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        RedundantObjcAttributeRuleExamples.triggeringExamples
    }
    var corrections: [Example: Example] {
        RedundantObjcAttributeRuleExamples.corrections
    }
}
