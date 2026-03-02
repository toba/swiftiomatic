struct NumberFormattingConfiguration: RuleConfiguration {
    let id = "number_formatting"
    let name = "Number Formatting"
    let summary = "Large numeric literals should use underscores for grouping"
    let scope: Scope = .suggest
    var nonTriggeringExamples: [Example] {
        [
              Example("let x = 1_000_000"),
              Example("let x = 100"),
              Example("let x = 0xFF"),
              Example("let x = 1_000"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("let x = ↓1000000"),
              Example("let x = ↓100000"),
            ]
    }
}
