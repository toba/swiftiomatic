struct SpaceAroundParensConfiguration: RuleConfiguration {
    let id = "space_around_parens"
    let name = "Space Around Parentheses"
    let summary = "No space between function name and opening paren; space required after closing paren before identifiers"
    let scope: Scope = .format
    let isCorrectable = true
}
