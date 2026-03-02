struct TrailingSemicolonConfiguration: RuleConfiguration {
    let id = "trailing_semicolon"
    let name = "Trailing Semicolon"
    let summary = "Lines should not have trailing semicolons"
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example("let a = 0"),
              Example("let a = 0; let b = 0"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("let a = 0↓;\n"),
              Example("let a = 0↓;\nlet b = 1"),
              Example("let a = 0↓; // a comment\n"),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("let a = 0↓;\n"): Example("let a = 0\n"),
              Example("let a = 0↓;\nlet b = 1"): Example("let a = 0\nlet b = 1"),
              Example("let foo = 12↓;  // comment\n"): Example("let foo = 12  // comment\n"),
            ]
    }
}
