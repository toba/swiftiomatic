struct MarkTypesConfiguration: RuleConfiguration {
    let id = "mark_types"
    let name = "Mark Types"
    let summary = "Top-level types and extensions should have MARK comments for organization"
    let scope: Scope = .suggest
}
