struct RedundantParensConfiguration: RuleConfiguration {
    let id = "redundant_parens"
    let name = "Redundant Parentheses"
    let summary = "Redundant parentheses around expressions in control flow statements should be removed"
    let scope: Scope = .format
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example("if foo == true {}"),
              Example("while !flag {}"),
              Example("let x = (a, b)"),
              Example("let x = (a + b) * c"),
              Example("switch (a, b) { default: break }"),
              Example("func foo(bar: Int) {}"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("if ↓(foo == true) {}"),
              Example("while ↓(flag) {}"),
              Example("guard ↓(condition) else { return }"),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("if ↓(foo == true) {}"): Example("if foo == true {}"),
              Example("while ↓(flag) {}"): Example("while flag {}"),
            ]
    }
}
