struct AcronymsConfiguration: RuleConfiguration {
    let id = "acronyms"
    let name = "Acronyms"
    let summary = "Acronyms in identifiers should be uppercased (e.g. `URL` not `Url`)"
    let scope: Scope = .suggest
    var nonTriggeringExamples: [Example] {
        [
              Example("let destinationURL: URL"),
              Example("let urlRouter: URLRouter"),
              Example("let screenIDs: [String]"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("let ↓destinationUrl: URL"),
              Example("let ↓urlRouter: UrlRouter"),
              Example("let ↓screenIds: [String]"),
            ]
    }
}
