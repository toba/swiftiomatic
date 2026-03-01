struct SelfBindingConfiguration: RuleConfiguration {
    let id = "self_binding"
    let name = "Self Binding"
    let summary = "Re-bind `self` to a consistent identifier name."
    let isCorrectable = true
    let isOptIn = true
}
