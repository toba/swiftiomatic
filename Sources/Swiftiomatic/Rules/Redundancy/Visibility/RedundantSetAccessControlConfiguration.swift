struct RedundantSetAccessControlConfiguration: RuleConfiguration {
    let id = "redundant_set_access_control"
    let name = "Redundant Access Control for Setter"
    let summary = "Property setter access level shouldn't be explicit if it's the same as the variable access level"
}
