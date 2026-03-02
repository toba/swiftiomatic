struct UnusedDeclarationConfiguration: RuleConfiguration {
    let id = "unused_declaration"
    let name = "Unused Declaration"
    let summary = "Declarations should be referenced at least once within all files linted"
    let isOptIn = true
    let requiresSourceKit = true
    let requiresCompilerArguments = true
    let requiresFileOnDisk = true
    let isCrossFile = true
    var nonTriggeringExamples: [Example] {
        UnusedDeclarationRuleExamples.nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        UnusedDeclarationRuleExamples.triggeringExamples
    }
}
