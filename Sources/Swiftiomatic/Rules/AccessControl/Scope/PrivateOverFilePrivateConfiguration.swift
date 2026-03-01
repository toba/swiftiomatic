struct PrivateOverFilePrivateConfiguration: RuleConfiguration {
    let id = "private_over_fileprivate"
    let name = "Private over Fileprivate"
    let summary = "Prefer `private` over `fileprivate` declarations"
    let isCorrectable = true
}
