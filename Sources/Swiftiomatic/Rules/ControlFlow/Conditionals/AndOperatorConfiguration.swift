struct AndOperatorConfiguration: RuleConfiguration {
    let id = "and_operator"
    let name = "And Operator"
    let summary = "Prefer comma over `&&` in `if`, `guard`, or `while` conditions"
    let scope: Scope = .suggest
}
