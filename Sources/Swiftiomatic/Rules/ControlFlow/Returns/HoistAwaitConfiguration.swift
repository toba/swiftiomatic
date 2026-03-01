struct HoistAwaitConfiguration: RuleConfiguration {
    let id = "hoist_await"
    let name = "Hoist Await"
    let summary = "Move `await` keyword to the outermost expression instead of nesting it inside arguments"
    let scope: Scope = .format
    let isCorrectable = true
}
