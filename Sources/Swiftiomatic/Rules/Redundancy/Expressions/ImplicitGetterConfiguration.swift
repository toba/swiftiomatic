struct ImplicitGetterConfiguration: RuleConfiguration {
    let id = "implicit_getter"
    let name = "Implicit Getter"
    let summary = "Computed read-only properties and subscripts should avoid using the get keyword."
}
