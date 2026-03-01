struct PreferSelfTypeOverTypeOfSelfConfiguration: RuleConfiguration {
    let id = "prefer_self_type_over_type_of_self"
    let name = "Prefer Self Type Over Type of Self"
    let summary = "Prefer `Self` over `type(of: self)` when accessing properties or calling methods"
    let isCorrectable = true
    let isOptIn = true
}
