struct ExplicitSelfConfiguration: RuleConfiguration {
    let id = "explicit_self"
    let name = "Explicit Self"
    let summary = "Instance variables and functions should be explicitly accessed with 'self.'"
    let isCorrectable = true
    let isOptIn = true
    let requiresSourceKit = true
    let requiresCompilerArguments = true
    let requiresFileOnDisk = true
    var nonTriggeringExamples: [Example] {
        ExplicitSelfRuleExamples.nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        ExplicitSelfRuleExamples.triggeringExamples
    }
    var corrections: [Example: Example] {
        ExplicitSelfRuleExamples.corrections
    }
}
