struct PrefixedTopLevelConstantConfiguration: RuleConfiguration {
    let id = "prefixed_toplevel_constant"
    let name = "Prefixed Top-Level Constant"
    let summary = "Top-level constants should be prefixed by `k`"
    let isOptIn = true
}
