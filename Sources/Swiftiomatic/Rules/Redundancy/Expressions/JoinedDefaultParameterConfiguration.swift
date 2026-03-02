struct JoinedDefaultParameterConfiguration: RuleConfiguration {
    let id = "joined_default_parameter"
    let name = "Joined Default Parameter"
    let summary = "Discouraged explicit usage of the default separator"
    let isCorrectable = true
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("let foo = bar.joined()"),
              Example("let foo = bar.joined(separator: \",\")"),
              Example("let foo = bar.joined(separator: toto)"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("let foo = bar.joined(↓separator: \"\")"),
              Example(
                """
                let foo = bar.filter(toto)
                             .joined(↓separator: ""),
                """,
              ),
              Example(
                """
                func foo() -> String {
                  return ["1", "2"].joined(↓separator: "")
                }
                """,
              ),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("let foo = bar.joined(↓separator: \"\")"): Example("let foo = bar.joined()"),
              Example("let foo = bar.filter(toto)\n.joined(↓separator: \"\")"):
                Example("let foo = bar.filter(toto)\n.joined()"),
              Example("func foo() -> String {\n   return [\"1\", \"2\"].joined(↓separator: \"\")\n}"):
                Example("func foo() -> String {\n   return [\"1\", \"2\"].joined()\n}"),
              Example("class C {\n#if true\nlet foo = bar.joined(↓separator: \"\")\n#endif\n}"):
                Example("class C {\n#if true\nlet foo = bar.joined()\n#endif\n}"),
            ]
    }
}
