struct AgentReviewConfiguration: RuleConfiguration {
    let id = "agent_review"
    let name = "Agent Review"
    let summary = "Lower-confidence checks that benefit from agent verification"
    let isOptIn = true
}
