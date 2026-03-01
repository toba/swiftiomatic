struct UnneededOverrideConfiguration: RuleConfiguration {
    let id = "unneeded_override"
    let name = "Unneeded Overridden Functions"
    let summary = "Remove overridden functions that don't do anything except call their super"
    let isCorrectable = true
}
