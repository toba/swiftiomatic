struct HoistTryConfiguration: RuleConfiguration {
    let id = "hoist_try"
    let name = "Hoist Try"
    let summary = "Move `try` keyword to the outermost expression instead of nesting it inside arguments"
    let scope: Scope = .format
    let isCorrectable = true
}
