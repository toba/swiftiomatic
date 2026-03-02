struct SpaceInsideParensConfiguration: RuleConfiguration {
    let id = "space_inside_parens"
    let name = "Space Inside Parentheses"
    let summary = "There should be no spaces immediately inside parentheses"
    let scope: Scope = .format
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example("(a, b)"),
              Example("foo(bar)"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("(↓ a, b)"),
              Example("foo(↓ bar )"),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("(↓ a, b )"): Example("(a, b)")
            ]
    }
}
