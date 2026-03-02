struct TrailingWhitespaceConfiguration: RuleConfiguration {
    let id = "trailing_whitespace"
    let name = "Trailing Whitespace"
    let summary = "Lines should not have trailing whitespace"
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example("let name: String\n"), Example("//\n"), Example("// \n"),
              Example("let name: String //\n"), Example("let name: String // \n"),
              Example("let stringWithSpace = \"hello \"\n"),
              Example(
                "let multiline = \"\"\"\n    line with spaces    \n    \"\"\"   \n",
                configuration: ["ignores_literals": true],
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("let name: String↓ \n"), Example("/* */ let name: String↓ \n"),
              Example(
                "let codeWithSpace = 123↓    \n", configuration: ["ignores_literals": true],
                shouldTestWrappingInComment: false,
              ),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("let name: String↓ \n"): Example("let name: String\n"),
              Example("/* */ let name: String↓ \n"): Example("/* */ let name: String\n"),
            ]
    }
}
