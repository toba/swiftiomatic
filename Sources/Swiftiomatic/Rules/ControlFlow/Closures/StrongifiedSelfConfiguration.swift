struct StrongifiedSelfConfiguration: RuleConfiguration {
    let id = "strongified_self"
    let name = "Strongified Self"
    let summary = "Remove backticks around `self` in optional unwrap expressions"
    let scope: Scope = .suggest
}
