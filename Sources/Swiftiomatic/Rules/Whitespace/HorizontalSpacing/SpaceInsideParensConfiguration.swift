struct SpaceInsideParensConfiguration: RuleConfiguration {
    let id = "space_inside_parens"
    let name = "Space Inside Parentheses"
    let summary = "There should be no spaces immediately inside parentheses"
    let scope: Scope = .format
    let isCorrectable = true
}
