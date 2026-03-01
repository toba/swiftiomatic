struct IdenticalOperandsConfiguration: RuleConfiguration {
    let id = "identical_operands"
    let name = "Identical Operands"
    let summary = "Comparing two identical operands is likely a mistake"
    let isOptIn = true
}
