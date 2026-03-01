struct UntypedErrorInCatchConfiguration: RuleConfiguration {
    let id = "untyped_error_in_catch"
    let name = "Untyped Error in Catch"
    let summary = "Catch statements should not declare error variables without type casting"
    let isCorrectable = true
    let isOptIn = true
}
