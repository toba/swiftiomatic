struct RedundantBackticksConfiguration: RuleConfiguration {
    let id = "redundant_backticks"
    let name = "Redundant Backticks"
    let summary = "Backtick-escaped identifiers that are not keywords in their context are redundant"
    let scope: Scope = .format
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example("let `class` = \"value\""),
              Example("func `init`() {}"),
              Example("let `self` = this"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("let ↓`foo` = bar"),
              Example("func ↓`myFunc`() {}"),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("let ↓`foo` = bar"): Example("let foo = bar")
            ]
    }
}
