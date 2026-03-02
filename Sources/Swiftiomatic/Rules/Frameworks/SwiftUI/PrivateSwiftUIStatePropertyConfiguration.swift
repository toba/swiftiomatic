struct PrivateSwiftUIStatePropertyConfiguration: RuleConfiguration {
    let id = "private_swiftui_state"
    let name = "Private SwiftUI State Properties"
    let summary = "SwiftUI state properties should be private"
    let isCorrectable = true
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        PrivateSwiftUIStatePropertyRuleExamples.nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        PrivateSwiftUIStatePropertyRuleExamples.triggeringExamples
    }
    var corrections: [Example: Example] {
        PrivateSwiftUIStatePropertyRuleExamples.corrections
    }
}
