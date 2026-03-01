struct DelegateToAsyncStreamConfiguration: RuleConfiguration {
    let id = "delegate_to_async_stream"
    let name = "Delegate to AsyncStream"
    let summary = "Protocol declarations where all methods are single-callback-shaped may benefit from an AsyncStream wrapper"
    let scope: Scope = .suggest
    let isOptIn = true
}
