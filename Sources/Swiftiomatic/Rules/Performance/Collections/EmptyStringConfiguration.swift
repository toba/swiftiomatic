struct EmptyStringConfiguration: RuleConfiguration {
    let id = "empty_string"
    let name = "Empty String"
    let summary = "Prefer checking `isEmpty` over comparing `string` to an empty string literal"
    let isOptIn = true
}
