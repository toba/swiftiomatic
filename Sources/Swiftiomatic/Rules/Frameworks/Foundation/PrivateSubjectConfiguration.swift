struct PrivateSubjectConfiguration: RuleConfiguration {
    let id = "private_subject"
    let name = "Private Combine Subject"
    let summary = "Combine Subject should be private"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        PrivateSubjectRuleExamples.nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        PrivateSubjectRuleExamples.triggeringExamples
    }
}
