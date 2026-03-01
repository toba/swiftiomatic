struct StrictFilePrivateConfiguration: RuleConfiguration {
    let id = "strict_fileprivate"
    let name = "Strict Fileprivate"
    let summary = "`fileprivate` should be avoided"
    let isOptIn = true
}
