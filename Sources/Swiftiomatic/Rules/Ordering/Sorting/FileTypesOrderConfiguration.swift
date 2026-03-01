struct FileTypesOrderConfiguration: RuleConfiguration {
    let id = "file_types_order"
    let name = "File Types Order"
    let summary = "Specifies how the types within a file should be ordered."
    let isOptIn = true
    let requiresSourceKit = true
}
