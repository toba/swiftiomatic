struct MultilineFunctionChainsConfiguration: RuleConfiguration {
    let id = "multiline_function_chains"
    let name = "Multiline Function Chains"
    let summary = "Chained function calls should be either on the same line, or one per line"
    let isOptIn = true
    let requiresSourceKit = true
}
