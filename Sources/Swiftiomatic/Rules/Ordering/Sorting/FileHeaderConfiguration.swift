struct FileHeaderConfiguration: RuleConfiguration {
    let id = "file_header"
    let name = "File Header"
    let summary = "Header comments should be consistent with project patterns. The CURRENT_FILENAME placeholder can optionally be used in the required and forbidden patterns. It will be replaced by the real file name."
    let isOptIn = true
}
