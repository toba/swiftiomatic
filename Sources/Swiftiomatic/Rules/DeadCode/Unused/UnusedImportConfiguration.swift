struct UnusedImportConfiguration: RuleConfiguration {
    let id = "unused_import"
    let name = "Unused Import"
    let summary = "All imported modules should be required to make the file compile"
    let isCorrectable = true
    let isOptIn = true
    let requiresSourceKit = true
    let requiresCompilerArguments = true
    let requiresFileOnDisk = true
    var nonTriggeringExamples: [Example] {
        UnusedImportRuleExamples.nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        UnusedImportRuleExamples.triggeringExamples
    }
    var corrections: [Example: Example] {
        UnusedImportRuleExamples.corrections
    }
}
