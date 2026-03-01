struct UnneededThrowsConfiguration: RuleConfiguration {
    let id = "unneeded_throws_rethrows"
    let name = "Unneeded (Re)Throws Keyword"
    let summary = "Non-throwing functions/properties/closures should not be marked as `throws` or `rethrows`."
    let isCorrectable = true
    let isOptIn = true
}
