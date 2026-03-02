struct DiscouragedOptionalCollectionConfiguration: RuleConfiguration {
    let id = "discouraged_optional_collection"
    let name = "Discouraged Optional Collection"
    let summary = "Prefer empty collection over optional collection"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        DiscouragedOptionalCollectionExamples.nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        DiscouragedOptionalCollectionExamples.triggeringExamples
    }
}
