struct PreferSwiftTestingConfiguration: RuleConfiguration {
    let id = "prefer_swift_testing"
    let name = "Prefer Swift Testing"
    let summary = "XCTest-based test suites can be migrated to the Swift Testing framework"
    let scope: Scope = .suggest
}
