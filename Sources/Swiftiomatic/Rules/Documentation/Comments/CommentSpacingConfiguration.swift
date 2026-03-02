struct CommentSpacingConfiguration: RuleConfiguration {
    let id = "comment_spacing"
    let name = "Comment Spacing"
    let summary = "Prefer at least one space after slashes for comments"
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                // This is a comment
                """,
              ),
              Example(
                """
                /// Triple slash comment
                """,
              ),
              Example(
                """
                // Multiline double-slash
                // comment
                """,
              ),
              Example(
                """
                /// Multiline triple-slash
                /// comment
                """,
              ),
              Example(
                """
                /// Multiline triple-slash
                ///   - This is indented
                """,
              ),
              Example(
                """
                // - MARK: Mark comment
                """,
              ),
              Example(
                """
                //: Swift Playground prose section
                """,
              ),
              Example(
                """
                ///////////////////////////////////////////////
                // Comment with some lines of slashes boxing it
                ///////////////////////////////////////////////
                """,
              ),
              Example(
                """
                //:#localized(key: "SwiftPlaygroundLocalizedProse")
                """,
              ),
              Example(
                """
                /* Asterisk comment */
                """,
              ),
              Example(
                """
                /*
                    Multiline asterisk comment
                */
                """,
              ),
              Example(
                """
                /*:
                    Multiline Swift Playground prose section
                */
                """,
              ),
              Example(
                """
                /*#-editable-code Swift Playground editable area*/default/*#-end-editable-code*/
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                //↓Something
                """,
              ),
              Example(
                """
                //↓MARK
                """,
              ),
              Example(
                """
                //↓👨‍👨‍👦‍👦Something
                """,
              ),
              Example(
                """
                func a() {
                    //↓This needs refactoring
                    print("Something")
                }
                //↓We should improve above function
                """,
              ),
              Example(
                """
                ///↓This is a comment
                """,
              ),
              Example(
                """
                /// Multiline triple-slash
                ///↓This line is incorrect, though
                """,
              ),
              Example(
                """
                //↓- MARK: Mark comment
                """,
              ),
              Example(
                """
                //:↓Swift Playground prose section
                """,
              ),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("//↓Something"): Example("// Something"),
              Example("//↓- MARK: Mark comment"): Example("// - MARK: Mark comment"),
              Example(
                """
                /// Multiline triple-slash
                ///↓This line is incorrect, though
                """,
              ): Example(
                """
                /// Multiline triple-slash
                /// This line is incorrect, though
                """,
              ),
              Example(
                """
                func a() {
                    //↓This needs refactoring
                    print("Something")
                }
                //↓We should improve above function
                """,
              ): Example(
                """
                func a() {
                    // This needs refactoring
                    print("Something")
                }
                // We should improve above function
                """,
              ),
            ]
    }
}
