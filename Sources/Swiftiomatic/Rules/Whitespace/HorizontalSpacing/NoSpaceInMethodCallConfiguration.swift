struct NoSpaceInMethodCallConfiguration: RuleConfiguration {
    let id = "no_space_in_method_call"
    let name = "No Space in Method Call"
    let summary = "Don't add a space between the method name and the parentheses"
    let isCorrectable = true
}
