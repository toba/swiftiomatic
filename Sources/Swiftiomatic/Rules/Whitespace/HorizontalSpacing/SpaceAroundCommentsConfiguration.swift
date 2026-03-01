struct SpaceAroundCommentsConfiguration: RuleConfiguration {
    let id = "space_around_comments"
    let name = "Space Around Comments"
    let summary = "There should be a space before line comments and around block comments"
    let scope: Scope = .format
    let isCorrectable = true
}
