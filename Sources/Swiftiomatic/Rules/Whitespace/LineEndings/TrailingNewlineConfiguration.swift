struct TrailingNewlineConfiguration: RuleConfiguration {
    let id = "trailing_newline"
    let name = "Trailing Newline"
    let summary = "Files should have a single trailing newline"
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example("let a = 0\n")
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("let a = 0"),
              Example("let a = 0\n\n"),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("let a = 0"): Example("let a = 0\n"),
              Example("let b = 0\n\n"): Example("let b = 0\n"),
              Example("let c = 0\n\n\n\n"): Example("let c = 0\n"),
            ]
    }
}
