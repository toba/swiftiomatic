struct UnusedEnumeratedConfiguration: RuleConfiguration {
    let id = "unused_enumerated"
    let name = "Unused Enumerated"
    let summary = "When the index or the item is not used, `.enumerated()` can be removed."
}
