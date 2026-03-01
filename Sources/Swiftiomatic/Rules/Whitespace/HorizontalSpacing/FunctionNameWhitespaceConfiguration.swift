struct FunctionNameWhitespaceConfiguration: RuleConfiguration {
    let id = "function_name_whitespace"
    let name = "Function Name Whitespace"
    let summary = "There should be consistent whitespace before and after function names and generic parameters."
    let isCorrectable = true
    let deprecatedAliases: Set<String> = ["operator_whitespace"]
}
