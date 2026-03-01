struct QuickDiscouragedPendingTestConfiguration: RuleConfiguration {
    let id = "quick_discouraged_pending_test"
    let name = "Quick Discouraged Pending Test"
    let summary = "This test won't run as long as it's marked pending"
    let isOptIn = true
}
