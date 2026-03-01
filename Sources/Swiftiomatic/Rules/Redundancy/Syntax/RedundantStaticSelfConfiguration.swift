struct RedundantStaticSelfConfiguration: RuleConfiguration {
    let id = "redundant_static_self"
    let name = "Redundant Static Self"
    let summary = "Explicit `Self` qualification is redundant in static context"
    let scope: Scope = .format
}
