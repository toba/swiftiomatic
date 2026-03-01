struct EmptyExtensionsConfiguration: RuleConfiguration {
    let id = "empty_extensions"
    let name = "Empty Extensions"
    let summary = "Empty extensions that don't add protocol conformance should be removed"
}
