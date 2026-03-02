struct EmptyBracesConfiguration: RuleConfiguration {
    let id = "empty_braces"
    let name = "Empty Braces"
    let summary = "Empty braces should not contain whitespace"
    let scope: Scope = .format
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example("func foo() {}"),
              Example("class Bar {}"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("func foo() ↓{ }"),
              Example(
                """
                func foo() ↓{

                }
                """,
              ),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("func foo() ↓{ }"): Example("func foo() {}")
            ]
    }
}
