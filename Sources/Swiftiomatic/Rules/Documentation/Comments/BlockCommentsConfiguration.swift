struct BlockCommentsConfiguration: RuleConfiguration {
    let id = "block_comments"
    let name = "Block Comments"
    let summary = "Block comments (`/* */`) should be converted to line comments (`//`)"
    let scope: Scope = .suggest
}
