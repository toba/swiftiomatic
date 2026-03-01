struct PrivateSwiftUIStatePropertyConfiguration: RuleConfiguration {
    let id = "private_swiftui_state"
    let name = "Private SwiftUI State Properties"
    let summary = "SwiftUI state properties should be private"
    let isCorrectable = true
    let isOptIn = true
}
