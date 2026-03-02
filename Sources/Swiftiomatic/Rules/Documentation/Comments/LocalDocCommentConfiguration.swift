struct LocalDocCommentConfiguration: RuleConfiguration {
    let id = "local_doc_comment"
    let name = "Local Doc Comment"
    let summary = "Prefer regular comments over doc comments in local scopes"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                func foo() {
                  // Local scope documentation should use normal comments.
                  print("foo")
                }
                """,
              ),
              Example(
                """
                /// My great property
                var myGreatProperty: String!
                """,
              ),
              Example(
                """
                /// Look here for more info: https://github.com.
                var myGreatProperty: String!
                """,
              ),
              Example(
                """
                /// Look here for more info:
                /// https://github.com.
                var myGreatProperty: String!
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                func foo() {
                  ↓/// Docstring inside a function declaration
                  print("foo")
                }
                """,
              )
            ]
    }
}
