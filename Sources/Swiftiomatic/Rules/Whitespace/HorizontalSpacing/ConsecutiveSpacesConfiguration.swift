struct ConsecutiveSpacesConfiguration: RuleConfiguration {
    let id = "consecutive_spaces"
    let name = "Consecutive Spaces"
    let summary = "Multiple consecutive spaces should be replaced with a single space"
    let scope: Scope = .format
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example("let foo = 5"),
              Example("// comment with   multiple spaces"),
              Example("/* block   comment */"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("let  ↓foo = 5"),
              Example("let foo =  ↓5"),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("let  ↓foo = 5"): Example("let foo = 5"),
              Example("let foo =  ↓5"): Example("let foo = 5"),
            ]
    }
}
