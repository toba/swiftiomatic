struct ToggleBoolConfiguration: RuleConfiguration {
    let id = "toggle_bool"
    let name = "Toggle Bool"
    let summary = "Prefer `someBool.toggle()` over `someBool = !someBool`"
    let isCorrectable = true
    let isOptIn = true
}
