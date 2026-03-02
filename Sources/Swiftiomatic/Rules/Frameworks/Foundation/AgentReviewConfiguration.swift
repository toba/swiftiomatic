struct AgentReviewConfiguration: RuleConfiguration {
    let id = "agent_review"
    let name = "Agent Review"
    let summary = "Lower-confidence checks that benefit from agent verification"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("let task = Task { await work() }"),
              Example("enum AppError: LocalizedError { case failed }"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("↓Task { await work() }"),
              Example("enum ↓AppError: Error { case failed }"),
            ]
    }
}
