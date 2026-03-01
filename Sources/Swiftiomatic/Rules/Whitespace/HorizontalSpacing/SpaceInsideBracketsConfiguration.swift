struct SpaceInsideBracketsConfiguration: RuleConfiguration {
    let id = "space_inside_brackets"
    let name = "Space Inside Brackets"
    let summary = "There should be no spaces immediately inside square brackets"
    let scope: Scope = .format
    let isCorrectable = true
}
