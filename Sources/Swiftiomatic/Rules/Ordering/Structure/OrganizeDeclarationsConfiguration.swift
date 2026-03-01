struct OrganizeDeclarationsConfiguration: RuleConfiguration {
    let id = "organize_declarations"
    let name = "Organize Declarations"
    let summary = "Declarations within type bodies should be organized by category (properties, lifecycle, methods)"
    let scope: Scope = .suggest
}
