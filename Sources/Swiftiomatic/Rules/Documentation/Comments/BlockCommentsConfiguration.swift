struct BlockCommentsConfiguration: RuleConfiguration {
    let id = "block_comments"
    let name = "Block Comments"
    let summary = "Block comments (`/* */`) should be converted to line comments (`//`)"
    let scope: Scope = .suggest
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                // A comment
                // on multiple lines
                """,
              ),
              Example(
                """
                /// A doc comment
                func foo() {}
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                ↓/* A comment
                   on multiple lines */
                """,
              )
            ]
    }
}
