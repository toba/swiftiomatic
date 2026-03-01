struct IsDisjointConfiguration: RuleConfiguration {
    let id = "is_disjoint"
    let name = "Is Disjoint"
    let summary = "Prefer using `Set.isDisjoint(with:)` over `Set.intersection(_:).isEmpty`"
}
