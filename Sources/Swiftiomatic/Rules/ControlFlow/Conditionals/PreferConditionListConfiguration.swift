struct PreferConditionListConfiguration: RuleConfiguration {
    let id = "prefer_condition_list"
    let name = "Prefer Condition List"
    let summary = "Prefer a condition list over chaining conditions with '&&'"
    let isCorrectable = true
    let isOptIn = true
}
