struct SpaceAroundCommentsConfiguration: RuleConfiguration {
    let id = "space_around_comments"
    let name = "Space Around Comments"
    let summary = "There should be a space before line comments and around block comments"
    let scope: Scope = .format
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example("let a = 5 // comment"),
              Example("foo() /* block */ bar()"),
              Example(
                """
                // line comment
                let a = 5
                """),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("let a = 5↓// comment")
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("let a = 5↓// comment"): Example("let a = 5 // comment")
            ]
    }
}
