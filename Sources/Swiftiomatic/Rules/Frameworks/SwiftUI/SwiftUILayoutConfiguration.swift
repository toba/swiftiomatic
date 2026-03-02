struct SwiftUILayoutConfiguration: RuleConfiguration {
    let id = "swiftui_layout"
    let name = "SwiftUI Layout"
    let summary = "Detects SwiftUI layout composition anti-patterns like nested NavigationStack or List inside ScrollView"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("NavigationStack { List { Text(\"Hello\") } }")
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("NavigationStack { ↓NavigationStack { Text(\"Hello\") } }")
            ]
    }
}
