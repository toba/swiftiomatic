struct SpaceAroundGenericsConfiguration: RuleConfiguration {
    let id = "space_around_generics"
    let name = "Space Around Generics"
    let summary = "There should be no space between an identifier and opening angle bracket"
    let scope: Scope = .format
    let isCorrectable = true
}
