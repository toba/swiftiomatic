struct NSObjectPreferIsEqualConfiguration: RuleConfiguration {
    let id = "nsobject_prefer_isequal"
    let name = "NSObject Prefer isEqual"
    let summary = "NSObject subclasses should implement isEqual instead of =="
    var nonTriggeringExamples: [Example] {
        NSObjectPreferIsEqualRuleExamples.nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        NSObjectPreferIsEqualRuleExamples.triggeringExamples
    }
}
