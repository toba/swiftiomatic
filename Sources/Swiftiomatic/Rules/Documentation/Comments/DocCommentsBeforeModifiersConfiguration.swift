struct DocCommentsBeforeModifiersConfiguration: RuleConfiguration {
    let id = "doc_comments_before_modifiers"
    let name = "Doc Comments Before Modifiers"
    let summary = "Doc comments should appear before any modifiers or attributes"
    let scope: Scope = .suggest
}
