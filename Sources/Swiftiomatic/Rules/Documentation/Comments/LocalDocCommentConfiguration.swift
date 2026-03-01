struct LocalDocCommentConfiguration: RuleConfiguration {
    let id = "local_doc_comment"
    let name = "Local Doc Comment"
    let summary = "Prefer regular comments over doc comments in local scopes"
    let isOptIn = true
}
