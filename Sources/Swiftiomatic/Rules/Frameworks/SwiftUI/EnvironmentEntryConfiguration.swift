struct EnvironmentEntryConfiguration: RuleConfiguration {
    let id = "environment_entry"
    let name = "Environment Entry"
    let summary = "SwiftUI EnvironmentKey conformances can be replaced with the @Entry macro"
    let scope: Scope = .suggest
}
