struct AcronymsConfiguration: RuleConfiguration {
    let id = "acronyms"
    let name = "Acronyms"
    let summary = "Acronyms in identifiers should be uppercased (e.g. `URL` not `Url`)"
    let scope: Scope = .suggest
}
