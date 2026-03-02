struct ClosingBraceConfiguration: RuleConfiguration {
    let id = "closing_brace"
    let name = "Closing Brace Spacing"
    let summary = "Closing brace with closing parenthesis should not have any whitespaces in the middle"
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example("[].map({ })"),
              Example("[].map(\n  { }\n)"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("[].map({ ↓} )"),
              Example("[].map({ ↓}\t)"),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("[].map({ ↓} )"): Example("[].map({ })")
            ]
    }
}
