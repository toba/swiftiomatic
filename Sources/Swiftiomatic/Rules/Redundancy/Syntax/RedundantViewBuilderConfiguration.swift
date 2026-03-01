struct RedundantViewBuilderConfiguration: RuleConfiguration {
    let id = "redundant_view_builder"
    let name = "Redundant ViewBuilder"
    let summary = "`@ViewBuilder` is redundant on the `body` property of View/ViewModifier or on single-expression bodies"
    let scope: Scope = .format
    let isCorrectable = true
}
