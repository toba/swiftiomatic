struct NoExplicitOwnershipConfiguration: RuleConfiguration {
    let id = "no_explicit_ownership"
    let name = "No Explicit Ownership"
    let summary = "Explicit ownership modifiers (`borrowing`, `consuming`) should not be used"
    let scope: Scope = .format
    let isCorrectable = true
}
