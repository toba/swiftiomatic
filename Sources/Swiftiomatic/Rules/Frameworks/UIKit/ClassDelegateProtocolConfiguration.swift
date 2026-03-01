struct ClassDelegateProtocolConfiguration: RuleConfiguration {
    let id = "class_delegate_protocol"
    let name = "Class Delegate Protocol"
    let summary = "Delegate protocols should be class-only so they can be weakly referenced"
}
