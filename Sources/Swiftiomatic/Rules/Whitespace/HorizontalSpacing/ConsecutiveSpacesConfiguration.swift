struct ConsecutiveSpacesConfiguration: RuleConfiguration {
    let id = "consecutive_spaces"
    let name = "Consecutive Spaces"
    let summary = "Multiple consecutive spaces should be replaced with a single space"
    let scope: Scope = .format
    let isCorrectable = true
}
