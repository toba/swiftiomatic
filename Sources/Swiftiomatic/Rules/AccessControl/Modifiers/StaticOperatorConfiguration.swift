struct StaticOperatorConfiguration: RuleConfiguration {
    let id = "static_operator"
    let name = "Static Operator"
    let summary = "Operators should be declared as static functions, not free functions"
    let isOptIn = true
}
