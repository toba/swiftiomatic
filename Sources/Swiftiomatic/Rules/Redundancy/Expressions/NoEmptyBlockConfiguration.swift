struct NoEmptyBlockConfiguration: RuleConfiguration {
    let id = "no_empty_block"
    let name = "No Empty Block"
    let summary = "Code blocks should contain at least one statement or comment"
    let isOptIn = true
}
