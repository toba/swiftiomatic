struct DocCommentsConfiguration: RuleConfiguration {
    let id = "doc_comments"
    let name = "Doc Comments"
    let summary = "API declarations should use doc comments (`///`) instead of regular comments (`//`)"
    let scope: Scope = .suggest
}
