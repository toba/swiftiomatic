struct OneDeclarationPerFileConfiguration: RuleConfiguration {
    let id = "one_declaration_per_file"
    let name = "One Declaration per File"
    let summary = "Only a single declaration is allowed in a file"
    let isOptIn = true
}
