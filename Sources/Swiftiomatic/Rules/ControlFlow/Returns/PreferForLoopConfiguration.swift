struct PreferForLoopConfiguration: RuleConfiguration {
    let id = "prefer_for_loop"
    let name = "Prefer For Loop"
    let summary = "`.forEach { }` calls can be replaced with `for ... in` loops for better readability"
    let scope: Scope = .suggest
}
