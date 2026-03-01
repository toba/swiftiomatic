struct RedundantSendableConfiguration: RuleConfiguration {
    let id = "redundant_sendable"
    let name = "Redundant Sendable"
    let summary = "Sendable conformance is redundant on an actor-isolated type"
    let isCorrectable = true
}
