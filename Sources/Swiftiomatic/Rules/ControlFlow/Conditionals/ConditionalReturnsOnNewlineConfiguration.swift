struct ConditionalReturnsOnNewlineConfiguration: RuleConfiguration {
    let id = "conditional_returns_on_newline"
    let name = "Conditional Returns on Newline"
    let summary = "Conditional statements should always return on the next line"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("guard true else {\n return true\n}"),
              Example("guard true,\n let x = true else {\n return true\n}"),
              Example("if true else {\n return true\n}"),
              Example("if true,\n let x = true else {\n return true\n}"),
              Example("if textField.returnKeyType == .Next {"),
              Example("if true { // return }"),
              Example(
                """
                guard something
                else { return }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("↓guard true else { return }"),
              Example("↓if true { return }"),
              Example("↓if true { break } else { return }"),
              Example("↓if true { break } else {       return }"),
              Example("↓if true { return \"YES\" } else { return \"NO\" }"),
              Example(
                """
                ↓guard condition else { XCTFail(); return }
                """,
              ),
            ]
    }
}
