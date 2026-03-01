struct NamingHeuristicsConfiguration: RuleConfiguration {
    let id = "naming_heuristics"
    let name = "Naming Heuristics"
    let summary = "Checks names against Swift API Design Guidelines: Bool assertions, protocol suffixes, factory prefixes"
    let isOptIn = true
    let canEnrichAsync = true
}
