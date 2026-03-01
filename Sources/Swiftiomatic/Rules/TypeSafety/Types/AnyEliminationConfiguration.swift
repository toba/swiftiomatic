struct AnyEliminationConfiguration: RuleConfiguration {
    let id = "any_elimination"
    let name = "Any Elimination"
    let summary = "Usage of Any/AnyObject erases type safety and should be replaced with specific types or generics"
    let scope: Scope = .suggest
    let isOptIn = true
    let canEnrichAsync = true
}
