struct ForWhereConfiguration: RuleConfiguration {
    let id = "for_where"
    let name = "Prefer For-Where"
    let summary = "`where` clauses are preferred over a single `if` inside a `for`"
}
