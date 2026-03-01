struct LowerACLThanParentConfiguration: RuleConfiguration {
    let id = "lower_acl_than_parent"
    let name = "Lower ACL than Parent"
    let summary = "Ensure declarations have a lower access control level than their enclosing parent"
    let isCorrectable = true
    let isOptIn = true
}
