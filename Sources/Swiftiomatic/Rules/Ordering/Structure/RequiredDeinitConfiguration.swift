struct RequiredDeinitConfiguration: RuleConfiguration {
    let id = "required_deinit"
    let name = "Required Deinit"
    let summary = "Classes should have an explicit deinit method"
    let isOptIn = true
}
