struct UnneededBreakInSwitchConfiguration: RuleConfiguration {
    let id = "unneeded_break_in_switch"
    let name = "Unneeded Break in Switch"
    let summary = "Avoid using unneeded break statements"
    let isCorrectable = true
}
