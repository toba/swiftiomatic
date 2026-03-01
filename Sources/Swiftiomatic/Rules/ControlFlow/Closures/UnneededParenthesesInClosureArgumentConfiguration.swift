struct UnneededParenthesesInClosureArgumentConfiguration: RuleConfiguration {
    let id = "unneeded_parentheses_in_closure_argument"
    let name = "Unneeded Parentheses in Closure Argument"
    let summary = "Parentheses are not needed when declaring closure arguments"
    let isCorrectable = true
    let isOptIn = true
}
