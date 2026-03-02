struct SortImportsConfiguration: RuleConfiguration {
    let id = "sort_imports"
    let name = "Sort Imports"
    let summary = "Import statements should be sorted alphabetically"
    let scope: Scope = .format
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                import Bar
                import Foo
                """,
              ),
              Example(
                """
                import Bar
                @testable import Foo
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                ↓import Foo
                import Bar
                """,
              )
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("↓import Foo\nimport Bar"): Example("import Bar\nimport Foo")
            ]
    }
}
