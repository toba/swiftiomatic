struct MissingDocsConfiguration: RuleConfiguration {
    let id = "missing_docs"
    let name = "Missing Docs"
    let summary = "Declarations should be documented."
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        MissingDocsRuleExamples.nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        MissingDocsRuleExamples.triggeringExamples
    }
}
