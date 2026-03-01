struct ExplicitACLConfiguration: RuleConfiguration {
    let id = "explicit_acl"
    let name = "Explicit ACL"
    let summary = "All declarations should specify Access Control Level keywords explicitly"
    let isOptIn = true
}
