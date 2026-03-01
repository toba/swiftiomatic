struct ControlStatementConfiguration: RuleConfiguration {
    let id = "control_statement"
    let name = "Control Statement"
    let summary = "`if`, `for`, `guard`, `switch`, `while`, and `catch` statements shouldn't unnecessarily wrap their conditionals or arguments in parentheses"
    let isCorrectable = true
}
