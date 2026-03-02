struct NoExplicitOwnershipConfiguration: RuleConfiguration {
    let id = "no_explicit_ownership"
    let name = "No Explicit Ownership"
    let summary = "Explicit ownership modifiers (`borrowing`, `consuming`) should not be used"
    let scope: Scope = .format
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
                    Example("func foo(_ bar: Bar) {}"),
                    Example("let borrowing = true"),
                ]
    }
    var triggeringExamples: [Example] {
        [
                    Example("func foo(_ bar: ↓consuming Bar) {}"),
                    Example("↓borrowing func foo() {}"),
                ]
    }
    var corrections: [Example: Example] {
        [
                    Example("func foo(_ bar: ↓consuming Bar) {}"): Example("func foo(_ bar: Bar) {}"),
                ]
    }
}
