struct RedundantInternalConfiguration: RuleConfiguration {
    let id = "redundant_internal"
    let name = "Redundant Internal"
    let summary = "Declarations are internal by default; the `internal` modifier is redundant"
    let scope: Scope = .format
    let isCorrectable = true
}
