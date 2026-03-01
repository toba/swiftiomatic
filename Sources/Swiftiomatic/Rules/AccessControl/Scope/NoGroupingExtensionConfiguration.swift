struct NoGroupingExtensionConfiguration: RuleConfiguration {
    let id = "no_grouping_extension"
    let name = "No Grouping Extension"
    let summary = "Extensions shouldn't be used to group code within the same source file"
    let isOptIn = true
}
