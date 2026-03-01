struct ConcurrencyModernizationConfiguration: RuleConfiguration {
    let id = "concurrency_modernization"
    let name = "Concurrency Modernization"
    let summary = "Flags GCD usage and legacy concurrency patterns that should use structured concurrency"
    let isOptIn = true
    let canEnrichAsync = true
}
