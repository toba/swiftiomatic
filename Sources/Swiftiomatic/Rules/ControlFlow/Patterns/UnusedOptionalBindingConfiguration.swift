struct UnusedOptionalBindingConfiguration: RuleConfiguration {
    let id = "unused_optional_binding"
    let name = "Unused Optional Binding"
    let summary = "Prefer `!= nil` over `let _ =`"
}
