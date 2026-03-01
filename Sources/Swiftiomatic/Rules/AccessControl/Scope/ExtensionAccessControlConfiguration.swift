struct ExtensionAccessControlConfiguration: RuleConfiguration {
    let id = "extension_access_control"
    let name = "Extension Access Control"
    let summary = "Members of an extension that share the same access level should have it hoisted to the extension"
    let scope: Scope = .suggest
}
