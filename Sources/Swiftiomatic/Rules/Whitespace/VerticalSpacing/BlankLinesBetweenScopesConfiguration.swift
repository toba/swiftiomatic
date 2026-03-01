struct BlankLinesBetweenScopesConfiguration: RuleConfiguration {
    let id = "blank_lines_between_scopes"
    let name = "Blank Lines Between Scopes"
    let summary = "There should be a blank line before type declarations and multi-line functions"
    let scope: Scope = .format
}
