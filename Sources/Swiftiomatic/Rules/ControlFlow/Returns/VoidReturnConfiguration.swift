struct VoidReturnConfiguration: RuleConfiguration {
    let id = "void_return"
    let name = "Void Return"
    let summary = "Prefer `-> Void` over `-> ()`"
    let isCorrectable = true
}
