struct EmptyCountConfiguration: RuleConfiguration {
    let id = "empty_count"
    let name = "Empty Count"
    let summary = "Prefer checking `isEmpty` over comparing `count` to zero"
    let isCorrectable = true
    let isOptIn = true
}
