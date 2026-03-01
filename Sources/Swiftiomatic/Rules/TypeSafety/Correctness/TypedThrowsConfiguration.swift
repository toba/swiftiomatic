struct TypedThrowsConfiguration: RuleConfiguration {
    let id = "typed_throws"
    let name = "Typed Throws"
    let summary = "Functions that throw a single error type should use typed throws"
    let scope: Scope = .suggest
    let isOptIn = true
    let canEnrichAsync = true
}
