struct UnneededEscapingConfiguration: RuleConfiguration {
    let id = "unneeded_escaping"
    let name = "Unneeded Escaping"
    let summary = "The `@escaping` attribute should only be used when the closure actually escapes."
    let isCorrectable = true
    let isOptIn = true
}
