struct UnusedControlFlowLabelConfiguration: RuleConfiguration {
    let id = "unused_control_flow_label"
    let name = "Unused Control Flow Label"
    let summary = "Unused control flow label should be removed"
    let isCorrectable = true
}
