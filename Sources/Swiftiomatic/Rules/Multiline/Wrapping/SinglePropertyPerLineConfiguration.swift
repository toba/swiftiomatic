struct SinglePropertyPerLineConfiguration: RuleConfiguration {
    let id = "single_property_per_line"
    let name = "Single Property Per Line"
    let summary = "Each variable declaration should declare only one property"
    let scope: Scope = .suggest
}
