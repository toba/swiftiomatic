struct RedundantFileprivateConfiguration: RuleConfiguration {
    let id = "redundant_fileprivate"
    let name = "Redundant Fileprivate"
    let summary = "`fileprivate` can be replaced with `private` when only accessed within the same declaration scope"
    let scope: Scope = .suggest
}
