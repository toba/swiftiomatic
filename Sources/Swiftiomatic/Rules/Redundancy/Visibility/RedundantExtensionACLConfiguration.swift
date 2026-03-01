struct RedundantExtensionACLConfiguration: RuleConfiguration {
    let id = "redundant_extension_acl"
    let name = "Redundant Extension ACL"
    let summary = "Access control modifiers on extension members are redundant when they match the extension's ACL"
    let scope: Scope = .format
    let isCorrectable = true
}
