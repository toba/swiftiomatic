struct SuperfluousElseConfiguration: RuleConfiguration {
    let id = "superfluous_else"
    let name = "Superfluous Else"
    let summary = "Else branches should be avoided when the previous if-block exits the current scope"
    let isCorrectable = true
    let isOptIn = true
}
