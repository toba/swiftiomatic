struct BalancedXCTestLifecycleConfiguration: RuleConfiguration {
    let id = "balanced_xctest_lifecycle"
    let name = "Balanced XCTest Life Cycle"
    let summary = "Test classes must implement balanced setUp and tearDown methods"
    let isOptIn = true
}
