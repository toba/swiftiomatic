struct NimbleOperatorConfiguration: RuleConfiguration {
    let id = "nimble_operator"
    let name = "Nimble Operator"
    let summary = "Prefer Nimble operator overloads over free matcher functions"
    let isCorrectable = true
    let isOptIn = true
}
