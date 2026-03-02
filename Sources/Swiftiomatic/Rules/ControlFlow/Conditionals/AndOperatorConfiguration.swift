struct AndOperatorConfiguration: RuleConfiguration {
    let id = "and_operator"
    let name = "And Operator"
    let summary = "Prefer comma over `&&` in `if`, `guard`, or `while` conditions"
    let scope: Scope = .suggest
    var nonTriggeringExamples: [Example] {
        [
              Example("if a, b {}"),
              Example("guard a, b else { return }"),
              Example("if a || b {}"),
              Example("let x = a && b"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("if a ↓&& b {}"),
              Example("guard a ↓&& b else { return }"),
            ]
    }
}
