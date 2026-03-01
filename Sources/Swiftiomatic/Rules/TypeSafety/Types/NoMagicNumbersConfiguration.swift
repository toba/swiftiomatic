struct NoMagicNumbersConfiguration: RuleConfiguration {
    let id = "no_magic_numbers"
    let name = "No Magic Numbers"
    let summary = "Magic numbers should be replaced by named constants"
    let isOptIn = true
}
