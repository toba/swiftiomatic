struct EmptyExtensionsConfiguration: RuleConfiguration {
    let id = "empty_extensions"
    let name = "Empty Extensions"
    let summary = "Empty extensions that don't add protocol conformance should be removed"
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                extension String: Equatable {}
                """,
              ),
              Example(
                """
                extension Foo {
                  func bar() {}
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                ↓extension String {}
                """,
              )
            ]
    }
}
