struct DiscouragedNoneNameConfiguration: RuleConfiguration {
    let id = "discouraged_none_name"
    let name = "Discouraged None Name"
    let summary = "Enum cases and static members named `none` are discouraged as they can conflict with `Optional<T>.none`."
    let isOptIn = true
}
