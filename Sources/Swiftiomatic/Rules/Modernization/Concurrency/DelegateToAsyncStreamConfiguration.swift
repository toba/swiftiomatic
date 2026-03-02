struct DelegateToAsyncStreamConfiguration: RuleConfiguration {
    let id = "delegate_to_async_stream"
    let name = "Delegate to AsyncStream"
    let summary = "Protocol declarations where all methods are single-callback-shaped may benefit from an AsyncStream wrapper"
    let scope: Scope = .suggest
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                protocol DataSource {
                    func numberOfItems() -> Int
                    func item(at index: Int) -> Item
                }
                """,
              )
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                ↓protocol DownloadDelegate {
                    func downloadDidStart(_ download: Download)
                    func downloadDidFinish(_ download: Download, data: Data)
                    func downloadDidFail(_ download: Download, error: Error)
                }
                """,
              )
            ]
    }
}
