struct OverrideInExtensionConfiguration: RuleConfiguration {
    let id = "override_in_extension"
    let name = "Override in Extension"
    let summary = "Extensions shouldn't override declarations"
    let isOptIn = true
}
