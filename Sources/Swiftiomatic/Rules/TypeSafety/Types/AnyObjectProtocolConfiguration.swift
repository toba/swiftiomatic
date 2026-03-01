struct AnyObjectProtocolConfiguration: RuleConfiguration {
    let id = "any_object_protocol"
    let name = "AnyObject Protocol"
    let summary = "Prefer `AnyObject` over `class` in protocol definitions"
    let scope: Scope = .suggest
}
