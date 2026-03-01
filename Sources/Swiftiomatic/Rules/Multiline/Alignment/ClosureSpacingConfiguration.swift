struct ClosureSpacingConfiguration: RuleConfiguration {
    let id = "closure_spacing"
    let name = "Closure Spacing"
    let summary = "Closure expressions should have a single space inside each brace"
    let isCorrectable = true
    let isOptIn = true
}
