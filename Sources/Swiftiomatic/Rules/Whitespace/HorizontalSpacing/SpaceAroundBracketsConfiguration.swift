struct SpaceAroundBracketsConfiguration: RuleConfiguration {
    let id = "space_around_brackets"
    let name = "Space Around Brackets"
    let summary = "There should be no space between an identifier and opening bracket, and space after closing bracket before identifiers"
    let scope: Scope = .format
    let isCorrectable = true
}
