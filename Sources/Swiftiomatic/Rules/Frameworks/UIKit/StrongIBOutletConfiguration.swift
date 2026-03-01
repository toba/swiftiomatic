struct StrongIBOutletConfiguration: RuleConfiguration {
    let id = "strong_iboutlet"
    let name = "Strong IBOutlet"
    let summary = "@IBOutlets shouldn't be declared as weak"
    let isCorrectable = true
    let isOptIn = true
}
