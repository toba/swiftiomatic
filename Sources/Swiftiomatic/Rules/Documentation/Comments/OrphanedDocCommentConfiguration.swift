struct OrphanedDocCommentConfiguration: RuleConfiguration {
    let id = "orphaned_doc_comment"
    let name = "Orphaned Doc Comment"
    let summary = "A doc comment should be attached to a declaration"
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                /// My great property
                var myGreatProperty: String!
                """,
              ),
              Example(
                """
                //////////////////////////////////////
                //
                // Copyright header.
                //
                //////////////////////////////////////
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
                ↓/// My great property
                // Not a doc string
                var myGreatProperty: String!
                """,
              ),
              Example(
                """
                ↓/// Look here for more info: https://github.com.
                // Not a doc string
                var myGreatProperty: String!
                """,
              ),
              Example(
                """
                ↓/// Look here for more info: https://github.com.


                // Not a doc string
                var myGreatProperty: String!
                """,
              ),
              Example(
                """
                ↓/// Look here for more info: https://github.com.
                // Not a doc string
                ↓/// My great property
                // Not a doc string
                var myGreatProperty: String!
                """,
              ),
              Example(
                """
                extension Nested {
                    ↓///
                    /// Look here for more info: https://github.com.

                    // Not a doc string
                    var myGreatProperty: String!
                }
                """,
              ),
            ]
    }
}
