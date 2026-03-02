struct EnvironmentEntryConfiguration: RuleConfiguration {
    let id = "environment_entry"
    let name = "Environment Entry"
    let summary = "SwiftUI EnvironmentKey conformances can be replaced with the @Entry macro"
    let scope: Scope = .suggest
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                extension EnvironmentValues {
                  @Entry var screenName: String = "default"
                }
                """,
              )
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                ↓struct ScreenNameKey: EnvironmentKey {
                  static var defaultValue: String { "default" }
                }
                """,
              )
            ]
    }
}
