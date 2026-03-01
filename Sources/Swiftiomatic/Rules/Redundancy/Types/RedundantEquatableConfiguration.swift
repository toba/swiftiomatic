struct RedundantEquatableConfiguration: RuleConfiguration {
    let id = "redundant_equatable"
    let name = "Redundant Equatable"
    let summary = "Structs conforming to Equatable can rely on synthesized `==` instead of implementing it manually"
    let scope: Scope = .suggest
}
