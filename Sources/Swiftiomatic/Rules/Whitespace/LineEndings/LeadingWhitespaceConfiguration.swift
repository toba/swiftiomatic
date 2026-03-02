struct LeadingWhitespaceConfiguration: RuleConfiguration {
    let id = "leading_whitespace"
    let name = "Leading Whitespace"
    let summary = "Files should not contain leading whitespace"
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example("//")
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("\n//"),
              Example(" //"),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("\n //", shouldTestMultiByteOffsets: false): Example("//")
            ]
    }
}
