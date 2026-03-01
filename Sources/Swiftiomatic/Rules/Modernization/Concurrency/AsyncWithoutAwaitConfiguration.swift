struct AsyncWithoutAwaitConfiguration: RuleConfiguration {
    let id = "async_without_await"
    let name = "Async Without Await"
    let summary = "Declaration should not be async if it doesn't use await"
    let isCorrectable = true
    let isOptIn = true
}
