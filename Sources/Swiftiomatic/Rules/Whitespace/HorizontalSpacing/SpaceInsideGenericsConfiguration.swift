struct SpaceInsideGenericsConfiguration: RuleConfiguration {
    let id = "space_inside_generics"
    let name = "Space Inside Generics"
    let summary = "There should be no spaces immediately inside angle brackets"
    let scope: Scope = .format
    let isCorrectable = true
}
