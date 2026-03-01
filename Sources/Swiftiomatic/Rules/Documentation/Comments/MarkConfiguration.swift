struct MarkConfiguration: RuleConfiguration {
    let id = "mark"
    let name = "Mark"
    let summary = "MARK comment should be in valid format. e.g. '// MARK: ...' or '// MARK: - ...'"
    let isCorrectable = true
}
