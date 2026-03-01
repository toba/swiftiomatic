struct EmptyParenthesesWithTrailingClosureConfiguration: RuleConfiguration {
    let id = "empty_parentheses_with_trailing_closure"
    let name = "Empty Parentheses with Trailing Closure"
    let summary = "When using trailing closures, empty parentheses should be avoided after the method call"
    let isCorrectable = true
}
