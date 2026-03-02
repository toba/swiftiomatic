struct DocCommentsConfiguration: RuleConfiguration {
    let id = "doc_comments"
    let name = "Doc Comments"
    let summary = "API declarations should use doc comments (`///`) instead of regular comments (`//`)"
    let scope: Scope = .suggest
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                /// A placeholder type
                class Foo {}
                """,
              ),
              Example(
                """
                class Foo {
                  // TODO: implement
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
                ↓// A placeholder type
                class Foo {}
                """,
              ),
              Example(
                """
                class Foo {
                  ↓// Does something
                  func bar() {}
                }
                """,
              ),
            ]
    }
}
