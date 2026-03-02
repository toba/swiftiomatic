struct FatalErrorMessageConfiguration: RuleConfiguration {
    let id = "fatal_error_message"
    let name = "Fatal Error Message"
    let summary = "A fatalError call should have a message"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                func foo() {
                  fatalError("Foo")
                }
                """,
              ),
              Example(
                """
                func foo() {
                  fatalError(x)
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                func foo() {
                  ↓fatalError("")
                }
                """,
              ),
              Example(
                """
                func foo() {
                  ↓fatalError()
                }
                """,
              ),
            ]
    }
}
