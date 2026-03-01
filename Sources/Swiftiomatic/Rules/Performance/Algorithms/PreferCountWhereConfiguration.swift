struct PreferCountWhereConfiguration: RuleConfiguration {
    let id = "prefer_count_where"
    let name = "Prefer count(where:)"
    let summary = "Use `count(where:)` instead of `filter(_:).count` for better performance"
}
