struct ExplicitTopLevelACLConfiguration: RuleConfiguration {
    let id = "explicit_top_level_acl"
    let name = "Explicit Top Level ACL"
    let summary = "Top-level declarations should specify Access Control Level keywords explicitly"
    let isOptIn = true
}
